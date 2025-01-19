CREATE DATABASE QLKTX
USE QLKTX
------------------------

--Tables

CREATE TABLE SINHVIEN (
    MASV INT PRIMARY KEY,
    HOTEN VARCHAR(100) NULL,
    GIOITINH VARCHAR(10) NULL,
    SDT VARCHAR(15) NULL,
    EMAIL VARCHAR(100) NULL
);

CREATE TABLE PHONG (
    MAPH INT PRIMARY KEY,
    LOAIPH VARCHAR(50) NULL,
    TANG INT NULL,
    SOSV INT NULL,
    TINHTRANG VARCHAR(50) NULL,
    LUONGDIEN FLOAT NULL,
    LUONGNUOC FLOAT NULL
);

CREATE TABLE TOANHA (
    MATOA INT PRIMARY KEY,
    CUMTOA VARCHAR(50) NULL,
	
);

CREATE TABLE QUANLY (
    MAQUANLY INT PRIMARY KEY,
    CHUCVU VARCHAR(50) NULL,
    MATOA INT,
    FOREIGN KEY (MATOA) REFERENCES TOANHA(MATOA)
);

CREATE TABLE NHACUNGCAP (
    MANHACC INT PRIMARY KEY,
    DV_CC_DICHVU VARCHAR(100) NULL
);

CREATE TABLE HOADON_DIEN (
    MAHDD INT PRIMARY KEY,
    MAPH INT,
    NGAYTAO smalldatetime NULL,
    TINHTRANG VARCHAR(50) NULL,
    CHISODIEN INT NULL,
    TONGTIEN_DIEN FLOAT NULL,
    HTHUCTHANHTOAN VARCHAR(50) NULL,
    FOREIGN KEY (MAPH) REFERENCES PHONG(MAPH)
);

CREATE TABLE HOADON_NUOC (
    MAHDN INT PRIMARY KEY,
    MAPH INT,
    NGAYTAO smalldatetime NULL,
    TINHTRANG VARCHAR(50) NULL,
    CHISONUOC INT NULL,
    TONGTIEN_NUOC FLOAT NULL,
    HTHUCTHANHTOAN VARCHAR(50) NULL,
    FOREIGN KEY (MAPH) REFERENCES PHONG(MAPH)
);

CREATE TABLE PHONG_TONG (
    MAPH INT PRIMARY KEY,
    TONGTIEN_DIEN FLOAT,
    TONGTIEN_NUOC FLOAT,
    TONGTIEN FLOAT
);

ALTER TABLE SINHVIEN
ADD MAPH INT NULL
ALTER TABLE SINHVIEN
ADD CONSTRAINT FK_SINHVIEN_MAPH FOREIGN KEY (MAPH) REFERENCES PHONG(MAPH)

ALTER TABLE PHONG
ADD MATOA INT NULL
ALTER TABLE PHONG
ADD CONSTRAINT FK_PHONG_MATOA FOREIGN KEY (MATOA) REFERENCES TOANHA(MATOA)

ALTER TABLE TOANHA
ADD MANCC INT NULL
ALTER TABLE TOANHA
ADD CONSTRAINT FK_TOANHA_MANHACC FOREIGN KEY (MANHACC) REFERENCES NHACUNGCAP(MANHACC)


--Select Statements
--1.Tìm hóa đơn điện có tổng tiền cao nhất
SELECT TOP 1 WITH TIES MAHDD
FROM HOADON_DIEN
ORDER BY HOADON_DIEN.TONGTIEN_DIEN DESC
--2.Tìm hóa đơn nước có tổng tiền nhỏ nhất
SELECT TOP 1 WITH TIES MAHDN
FROM HOADON_NUOC
ORDER BY HOADON_NUOC.TONGTIEN_NUOC ASC
--3.Lấy thông tin tất cả các hóa đơn điện đã thanh toán của phòng B102 trong năm 2017
SELECT * FROM HOADON_DIEN HDD
WHERE TINHTRANG = N'Đã thanh toán' AND MAPH = '102' AND YEAR(HDD.NGAYTAO) = '2017';
--4.Lấy thông tin tất cả các hóa đơn nước sẽ thanh toán sau trong tháng 3
SELECT * FROM HOADON_NUOC HDN
WHERE TINHTRANG = N'Thanh toán sau' AND MONTH(HDN.NGAYTAO) = '3';
--5.Lấy thông tin mã quản lí của cụm tòa D2
SELECT MAQUANLY
FROM QUANLY QL JOIN TOANHA TN ON QL.MATOA = TN.MATOA
WHERE CUMTOA = 'D2';
--6.Lấy chỉ số điện của hóa đơn điện được tạo trong khoảng thời gian 1/1/2021 tới ngày 31/12/2021 có hình thức thanh toán là trực tiếp bao gồm cả thông tin về loại phòng, số tầng,
--số lượng sinh viên.
SELECT HDD.CHISODIEN, P.LOAIPH, P.TANG, P.SOSV
FROM HOADON_DIEN HDD
JOIN PHONG P ON HDD.MAPH = P.MAPH
WHERE HDD.NGAYTAO BETWEEN '2021-1-1' AND '2021-12-31'
AND HDD.HTHUCTHANHTOAN = N'Trực tiếp';

--Trigger
--TRigger ngăn thêm sinh viên vào phòng đã đầy
CREATE TRIGGER Them_SVmoi
ON SINHVIEN
INSTEAD OF INSERT
AS
BEGIN
    DECLARE @MAPH INT;
    DECLARE @So_SV_ToiDa INT;
    DECLARE @SucChua_HienTai INT;

    SELECT @MAPH = i.MAPH, @So_SV_ToiDa = p.SOSV, @SucChua_HienTai = COUNT(s.MASV)
    FROM inserted i
    JOIN PHONG p ON i.MAPH = p.MAPH
    LEFT JOIN SINHVIEN s ON i.MAPH = s.MAPH
    GROUP BY i.MAPH, p.SOSV;

    IF (@SucChua_HienTai + (SELECT COUNT(*) FROM inserted) <= @So_SV_ToiDa)
    BEGIN
        INSERT INTO SINHVIEN (MASV, HOTEN, GIOITINH, SDT, EMAIL, MAPH)
        SELECT MASV, HOTEN, GIOITINH, SDT, EMAIL, MAPH
        FROM inserted;
    END
    ELSE
    BEGIN
        RAISERROR ('Phòng đã đạt số sinh viên tối đa.', 16, 1);
    END;
END;

--Trigger Ngăn không thêm hóa đơn điện nước vào phòng không có sinh viên
CREATE TRIGGER Them_HDD
ON HOADON_DIEN
INSTEAD OF INSERT
AS
BEGIN
    DECLARE @MAPH INT;

    SELECT @MAPH = i.MAPH
    FROM inserted i
    JOIN PHONG p ON i.MAPH = p.MAPH;

    IF EXISTS (SELECT 1 FROM SINHVIEN WHERE MAPH = @MAPH)
    BEGIN
        INSERT INTO HOADON_DIEN (MAHDD, MAPH, NGAYTAO, TINHTRANG, CHISODIEN, TONGTIEN_DIEN, HTHUCTHANHTOAN)
        SELECT MAHDD, MAPH, NGAYTAO, TINHTRANG, CHISODIEN, TONGTIEN_DIEN, HTHUCTHANHTOAN
        FROM inserted;
    END
    ELSE
    BEGIN
        RAISERROR ('Không thể thêm hóa đơn vì phòng không có sinh viên.', 16, 1);
    END;
END;

CREATE TRIGGER Them_HDN
ON HOADON_NUOC
INSTEAD OF INSERT
AS
BEGIN
    DECLARE @MAPH INT;

    SELECT @MAPH = i.MAPH
    FROM inserted i
    JOIN PHONG p ON i.MAPH = p.MAPH;

    IF EXISTS (SELECT 1 FROM SINHVIEN WHERE MAPH = @MAPH)
    BEGIN
        INSERT INTO HOADON_NUOC (MAHDN, MAPH, NGAYTAO, TINHTRANG, CHISONUOC, TONGTIEN_NUOC, HTHUCTHANHTOAN)
        SELECT MAHDN, MAPH, NGAYTAO, TINHTRANG, CHISONUOC, TONGTIEN_NUOC, HTHUCTHANHTOAN
        FROM inserted;
    END
    ELSE
    BEGIN
        RAISERROR ('Không thể thêm hóa đơn vì phòng không có sinh viên.', 16, 1);
    END;
END;

--Cursor
--Sử dụng con trỏ để tính tổng tiền và cập nhật vào bảng tổng
DECLARE @MAPH INT;
DECLARE @TONGTIEN_DIEN FLOAT;
DECLARE @TONGTIEN_NUOC FLOAT;
DECLARE @TONGTIEN FLOAT;

-- Khai báo con trỏ cho các phòng
DECLARE CUR_PHONG_SUM CURSOR FOR
SELECT MAPH FROM PHONG;

OPEN CUR_PHONG;

FETCH NEXT FROM CUR_PHONG_SUM INTO @MAPH;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Tính tổng tiền điện
    SELECT @TONGTIEN_DIEN = SUM(TONGTIEN_DIEN)
    FROM HOADON_DIEN
    WHERE MAPH = @MAPH;

    -- Tính tổng tiền nước
    SELECT @TONGTIEN_NUOC = SUM(TONGTIEN_NUOC)
    FROM HOADON_NUOC
    WHERE MAPH = @MAPH;

    -- Tính tổng tiền
    SET @TONGTIEN = ISNULL(@TONGTIEN_DIEN, 0) + ISNULL(@TONGTIEN_NUOC, 0);

    -- Cập nhật
    IF EXISTS (SELECT 1 FROM PHONG_TONG WHERE MAPH = @MAPH)
    BEGIN
        UPDATE PHONG_TONG
        SET TONGTIEN_DIEN = @TONGTIEN_DIEN,
            TONGTIEN_NUOC = @TONGTIEN_NUOC,
            TONGTIEN = @TONGTIEN
        WHERE MAPH = @MAPH;
    END
    ELSE
    BEGIN
        INSERT INTO PHONG_TONG (MAPH, TONGTIEN_DIEN, TONGTIEN_NUOC, TONGTIEN)
        VALUES (@MAPH, @TONGTIEN_DIEN, @TONGTIEN_NUOC, @TONGTIEN);
    END;

    FETCH NEXT FROM cur_phong INTO @MAPH;
END;

CLOSE cur_phong;
DEALLOCATE cur_phong;

--Function
--Tính tổng tiền điện và nước của 1 phòng
CREATE FUNCTION Tinh_Dien_Nuoc
(
    @MAPH INT,
    @THANG INT,
    @NAM INT
)
RETURNS @ResultTable TABLE
(
    TienDien FLOAT,
    TienNuoc FLOAT,
    Tong_Tien FLOAT
)
AS
BEGIN
    DECLARE @TongDien FLOAT;
    DECLARE @TongNuoc FLOAT;

    SELECT @TongDien = SUM(TONGTIEN_DIEN) 
    FROM HOADON_DIEN
    WHERE MAPH = @MAPH
    AND MONTH(NGAYTAO) = @Thang
    AND YEAR(NGAYTAO) = @Nam;

    SELECT @TongNuoc = SUM(TONGTIEN_NUOC) 
    FROM HOADON_NUOC
    WHERE MAPH = @MAPH
    AND MONTH(NGAYTAO) = @Thang
    AND YEAR(NGAYTAO) = @Nam;

    INSERT INTO @ResultTable (TienDien, TienNuoc, Tong_Tien)
    VALUES (@TongDien, @TongNuoc, @TongDien + @TongNuoc);

    RETURN;
END;
GO

SELECT * FROM Tinh_Dien_Nuoc(1, 10, 2023);

--Tính số sinh viên của 1 phòng
CREATE FUNCTION Tinh_SoSV
(
    @MAPH INT
)
RETURNS INT
AS
BEGIN
    DECLARE @SoSinhVien INT;

    -- Đếm số sinh viên trong phòng
    SELECT @SoSinhVien = COUNT(*)
    FROM SINHVIEN
    WHERE MAPH = @MAPH;

    RETURN @SoSinhVien;
END;
GO

SELECT Tinh_SoSV(*) AS SoSinhVien;

--Tính số phòng 1 quản lý quản lý
CREATE FUNCTION Tinh_SoPhongQuanLy
(
    @MAQUANLY INT
)
RETURNS INT
AS
BEGIN
    DECLARE @SoPhong INT;
    SELECT @SoPhong = COUNT(*)
    FROM PHONG P
    INNER JOIN TOANHA T ON P.MATOA = T.MATOA
    INNER JOIN QUANLY Q ON T.MATOA = Q.MATOA
    WHERE Q.MAQUANLY = @MAQUANLY;

    RETURN @SoPhong;
END;
GO

SELECT Tinh_SoPhongQuanLy(*) AS SoPhongQuanLy;

--Login&User
--Tạo login và user tương ứng
	--Sinh viên
create login SinhVien1 with password='sinhvien1'
create login SinhVien2 with password='sinhvien2'
create login SinhVien3 with password='sinhvien3'
create login SinhVien4 with password='sinhvien4'
create login SinhVien5 with password='sinhvien5'
create login SinhVien6 with password='sinhvien6'
create login SinhVien7 with password='sinhvien7'
create login SinhVien8 with password='sinhvien8'
create login SinhVien9 with password='sinhvien9'
create login SinhVien10 with password='sinhvien10'
create user sv01 for SinhVien1
create user sv02 for SinhVien2
create user sv03 for SinhVien3
create user sv04 for SinhVien4
create user sv05 for SinhVien5
create user sv06 for SinhVien6
create user sv07 for SinhVien7
create user sv08 for SinhVien8
create user sv09 for SinhVien9
create user sv10 for SinhVien10
	-- Quản lý
create login QuanLy1 with password='quanly1'
create login QuanLy2 with password='quanly2'
create user qly01 for login QuanLy1
create user qly02 for login QuanLy2

--Tạo role + add role
	--Role sinh viên
create role R_SinhVien
	--Role quản lý
create role R_QuanLy
--Tạo nhóm cho roles
	--sv01 -> sv10 thuộc R_SinhVien
exec sp_addrolemember 'R_SinhVien', 'sv01'
exec sp_addrolemember 'R_SinhVien', 'sv02'
exec sp_addrolemember 'R_SinhVien', 'sv03'
exec sp_addrolemember 'R_SinhVien', 'sv04'
exec sp_addrolemember 'R_SinhVien', 'sv05'
exec sp_addrolemember 'R_SinhVien', 'sv06'
exec sp_addrolemember 'R_SinhVien', 'sv07'
exec sp_addrolemember 'R_SinhVien', 'sv08'
exec sp_addrolemember 'R_SinhVien', 'sv09'
exec sp_addrolemember 'R_SinhVien', 'sv10'
	--qly01, qly02 thuộc R_QuanLy
exec sp_addrolemember 'R_QuanLy', 'qly01'
exec sp_addrolemember 'R_QuanLy', 'qly02'
--Phân quyền
	--Role sinh viên
grant select on SINHVIEN to R_SinhVien
grant select on PHONG to R_SinhVien
grant select on HOADON_DIEN to R_SinhVien
grant select on HOADON_NUOC to R_SinhVien
	--Role quản lý
grant select, insert, update, delete on PHONG to R_Quanly
grant select, insert, update, delete on TOANHA to R_Quanly
grant select, insert, update, delete on QUANLY to R_Quanly
grant select, insert, update, delete on NHACUNGCAP to R_Quanly
grant select, insert, update, delete on HOADON_DIEN to R_Quanly
grant select, insert, update, delete on HOADON_NUOC to R_Quanly

--Stored Procedure
--Thêm sinh viên mới với tham số đầu vào: MASV,HOTEN,GIOITINH,SDT,EMAIL
CREATE PROCEDURE STP_ThemSinhVien
(
	@MASV INT, @HOTEN VARCHAR(100), @GIOITINH VARCHAR(10), @SDT VARCHAR(15), @EMAIL VARCHAR(100), @MAPH INT
)
AS
BEGIN
	IF NOT EXISTS ( SELECT * FROM SINHVIEN
					WHERE MASV LIKE @MASV )
					BEGIN
						INSERT INTO SINHVIEN VALUES(@MASV, @HOTEN, @GIOITINH, @SDT ,@EMAIL, @MAPH)
						PRINT 'Insert Succesfully'
					END
	ELSE
					BEGIN
						PRINT 'Duplicated values !'
					END
END
GO
--Tìm quản lý dựa trên mã tòa
CREATE PROCEDURE STP_TimQuanLy
(
	@Matoa INT
)
AS
BEGIN 
	SELECT MAQUANLY, TOANHA.MATOA
	FROM QUANLY
	JOIN TOANHA ON QUANLY.MATOA = TOANHA.MATOA
	AND TOANHA.MATOA LIKE @Matoa
END
GO

--View
--Thống kê số lượng sinh viên trong 1 phòng
CREATE VIEW SoLuongSV_1Phong AS
SELECT 
    P.MAPH,
    P.LOAIPH,
    P.TANG,
    P.SOSV,
    P.TINHTRANG,
    COUNT(S.MASV) AS SoLuongSinhVien
FROM PHONG P
LEFT JOIN SINHVIEN S ON P.MAPH = S.MAPH
GROUP BY 
    P.MAPH,
    P.LOAIPH,
    P.TANG,
    P.SOSV,
    P.TINHTRANG;
GO

SELECT * FROM SoLuongSV_1Phong

--Thống kê số lượng phòng 1 quản lý quản lý
CREATE VIEW SoPH_QuanLy AS
SELECT 
    Q.MAQUANLY,
    Q.CHUCVU,
    Q.MATOA,
    COUNT(P.MAPH) AS SoLuongPhong
FROM QUANLY Q
INNER JOIN TOANHA T ON Q.MATOA = T.MATOA
INNER JOIN PHONG P ON T.MATOA = P.MATOA
GROUP BY 
    Q.MAQUANLY,
    Q.CHUCVU,
    Q.MATOA;
GO

SELECT * FROM SoPH_QuanLy;
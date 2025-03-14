-- Step 1: Create Database
CREATE DATABASE SportsEquipmentInventory;
GO

USE SportsEquipmentInventory;
GO

-- Step 2: Create Tables

-- Customer Table
CREATE TABLE Customer (
    CustomerID INT IDENTITY(1,1) PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Email VARCHAR(100) UNIQUE,
    Phone VARCHAR(15),
    Address TEXT
);
GO

-- Categories Table
CREATE TABLE Categories (
    CategoryID INT IDENTITY(1,1) PRIMARY KEY,
    CategoryName VARCHAR(100) NOT NULL
);
GO

-- Equipment Table
CREATE TABLE Equipment (
    EquipmentID INT IDENTITY(1,1) PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    CategoryID INT FOREIGN KEY REFERENCES Categories(CategoryID),
    Quantity INT CHECK (Quantity >= 0),
    Price DECIMAL(10,2)
);
GO

-- Supplier Table
CREATE TABLE Supplier (
    SupplierID INT IDENTITY(1,1) PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Contact VARCHAR(50),
    Email VARCHAR(100) UNIQUE,
    Address TEXT
);
GO

-- Transaction Table
CREATE TABLE TransactionTable (
    TransactionID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT FOREIGN KEY REFERENCES Customer(CustomerID),
    EquipmentID INT FOREIGN KEY REFERENCES Equipment(EquipmentID),
    Quantity INT CHECK (Quantity > 0),
    TotalPrice DECIMAL(10,2),
    TransactionDate DATETIME DEFAULT GETDATE()
);
GO

-- Penalty Table
CREATE TABLE Penalty (
    PenaltyID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT FOREIGN KEY REFERENCES Customer(CustomerID),
    Amount DECIMAL(10,2),
    Reason TEXT,
    DateIssued DATETIME DEFAULT GETDATE()
);
GO

-- Step 3: Insert Sample Data

-- Insert 5 Customers
INSERT INTO Customer (Name, Email, Phone, Address) VALUES 
('John Doe', 'john@example.com', '1234567890', '123 Street, City'),
('Jane Smith', 'jane@example.com', '9876543210', '456 Avenue, City'),
('Alice Johnson', 'alice@example.com', '5551234567', '789 Road, Town'),
('Bob Brown', 'bob@example.com', '4449876543', '321 Lane, Village'),
('Charlie Davis', 'charlie@example.com', '3334567890', '654 Boulevard, County');
GO

-- Insert 5 Categories
INSERT INTO Categories (CategoryName) VALUES 
('Cricket'), ('Football'), ('Tennis'), ('Basketball'), ('Badminton');
GO

-- Insert 5 Equipment
INSERT INTO Equipment (Name, CategoryID, Quantity, Price) VALUES 
('Cricket Bat', 1, 10, 1200.50),
('Football', 2, 15, 800.75),
('Tennis Racket', 3, 8, 1500.00),
('Basketball', 4, 20, 600.00),
('Badminton Racket', 5, 12, 900.00);
GO

-- Insert 5 Suppliers
INSERT INTO Supplier (Name, Contact, Email, Address) VALUES 
('ABC Sports', '123-456', 'abc@sports.com', '789 Street, City'),
('XYZ Equipment', '987-654', 'xyz@equip.com', '101 Avenue, City'),
('Sports World', '555-123', 'sports@world.com', '202 Road, Town'),
('Global Gear', '444-987', 'global@gear.com', '303 Lane, Village'),
('Elite Sports', '333-456', 'elite@sports.com', '404 Boulevard, County');
GO

-- Insert 5 Transactions
INSERT INTO TransactionTable (CustomerID, EquipmentID, Quantity, TotalPrice) VALUES 
(1, 1, 2, 2401.00), -- John buys 2 Cricket Bats
(2, 2, 1, 800.75),  -- Jane buys 1 Football
(3, 3, 1, 1500.00), -- Alice buys 1 Tennis Racket
(4, 4, 3, 1800.00), -- Bob buys 3 Basketballs
(5, 5, 2, 1800.00); -- Charlie buys 2 Badminton Rackets
GO

-- Insert 5 Penalties
INSERT INTO Penalty (CustomerID, Amount, Reason) VALUES 
(1, 100.00, 'Late return'),
(2, 50.00, 'Damaged equipment'),
(3, 75.00, 'Lost item'),
(4, 200.00, 'Late payment'),
(5, 150.00, 'Unauthorized use');
GO

-- Step 4: Stored Procedures

-- Add New Equipment
CREATE PROCEDURE AddEquipment
    @Name VARCHAR(100),
    @CategoryID INT,
    @Quantity INT,
    @Price DECIMAL(10,2)
AS
BEGIN
    INSERT INTO Equipment (Name, CategoryID, Quantity, Price)
    VALUES (@Name, @CategoryID, @Quantity, @Price);
END;
GO

-- Process Transaction with Exception Handling
CREATE PROCEDURE ProcessTransaction
    @CustomerID INT,
    @EquipmentID INT,
    @Quantity INT
AS
BEGIN
    DECLARE @TotalPrice DECIMAL(10,2);
    DECLARE @AvailableQuantity INT;

    -- Check available quantity
    SELECT @AvailableQuantity = Quantity FROM Equipment WHERE EquipmentID = @EquipmentID;

    IF @AvailableQuantity < @Quantity
    BEGIN
        RAISERROR ('Not enough stock available', 16, 1);
        RETURN;
    END;

    -- Calculate total price
    SELECT @TotalPrice = Price * @Quantity FROM Equipment WHERE EquipmentID = @EquipmentID;

    -- Insert into Transaction Table
    INSERT INTO TransactionTable (CustomerID, EquipmentID, Quantity, TotalPrice)
    VALUES (@CustomerID, @EquipmentID, @Quantity, @TotalPrice);

    -- Update Equipment Stock
    UPDATE Equipment SET Quantity = Quantity - @Quantity WHERE EquipmentID = @EquipmentID;

    PRINT 'Transaction Processed Successfully';
END;
GO

-- Step 5: Trigger to Prevent Negative Quantity
CREATE TRIGGER PreventNegativeQuantity
ON Equipment
AFTER UPDATE
AS
BEGIN
    IF EXISTS (SELECT * FROM inserted WHERE Quantity < 0)
    BEGIN
        RAISERROR ('Quantity cannot be negative', 16, 1);
        ROLLBACK TRANSACTION;
    END;
END;
GO

-- Step 6: User-Defined Functions (UDFs)

-- Scalar Function: Get Total Penalty Amount for a Customer
CREATE FUNCTION GetTotalPenalty (@CustomerID INT)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @Total DECIMAL(10,2);
    SELECT @Total = SUM(Amount) FROM Penalty WHERE CustomerID = @CustomerID;
    RETURN ISNULL(@Total, 0);
END;
GO

-- Table-Valued Function: Get All Transactions of a Customer
CREATE FUNCTION GetCustomerTransactions (@CustomerID INT)
RETURNS TABLE
AS
RETURN
(
    SELECT * FROM TransactionTable WHERE CustomerID = @CustomerID
);
GO

-- Step 7: Testing and Execution

-- Execute Stored Procedures
EXEC AddEquipment 'Tennis Racket', 3, 5, 1500.00;
GO

EXEC ProcessTransaction 1, 1, 2; -- Customer 1 buying 2 Cricket Bats
GO

EXEC ProcessTransaction 2, 2, 3; -- Customer 2 buying 3 Footballs
GO

-- Execute User-Defined Functions
DECLARE @PenaltyAmount DECIMAL(10,2);
SET @PenaltyAmount = dbo.GetTotalPenalty(1);
PRINT 'Total Penalty Amount: ' + CAST(@PenaltyAmount AS VARCHAR);
GO

SELECT * FROM dbo.GetCustomerTransactions(1);
GO

-- Testing Trigger (This should fail)
UPDATE Equipment SET Quantity = 5 WHERE EquipmentID = 1;
GO

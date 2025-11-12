CREATE DATABASE IF NOT EXISTS hospital_db;
USE hospital_db;

CREATE TABLE department (
  department_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  description TEXT
) ENGINE=InnoDB;

CREATE TABLE doctor (
  doctor_id INT AUTO_INCREMENT PRIMARY KEY,
  first_name VARCHAR(50) NOT NULL,
  last_name VARCHAR(50) NOT NULL,
  department_id INT,
  phone VARCHAR(20),
  email VARCHAR(100),
  specialization VARCHAR(100),
  CONSTRAINT fk_doctor_department FOREIGN KEY (department_id) REFERENCES department(department_id)
) ENGINE=InnoDB;

CREATE TABLE patient (
  patient_id INT AUTO_INCREMENT PRIMARY KEY,
  first_name VARCHAR(50) NOT NULL,
  last_name VARCHAR(50) NOT NULL,
  dob DATE,
  gender ENUM('M','F','Other') DEFAULT 'Other',
  phone VARCHAR(20),
  email VARCHAR(100),
  address TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE room (
  room_id INT AUTO_INCREMENT PRIMARY KEY,
  room_no VARCHAR(20) NOT NULL,
  floor INT,
  type ENUM('General','Semi-Private','Private','ICU') DEFAULT 'General'
) ENGINE=InnoDB;

CREATE TABLE bed (
  bed_id INT AUTO_INCREMENT PRIMARY KEY,
  room_id INT NOT NULL,
  bed_no VARCHAR(10) NOT NULL,
  status ENUM('Available','Occupied','Maintenance') DEFAULT 'Available',
  CONSTRAINT fk_bed_room FOREIGN KEY (room_id) REFERENCES room(room_id)
) ENGINE=InnoDB;

CREATE TABLE appointment (
  appointment_id INT AUTO_INCREMENT PRIMARY KEY,
  patient_id INT NOT NULL,
  doctor_id INT NOT NULL,
  appointment_datetime DATETIME NOT NULL,
  reason TEXT,
  status ENUM('Scheduled','Completed','Cancelled','No-Show') DEFAULT 'Scheduled',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_app_patient FOREIGN KEY (patient_id) REFERENCES patient(patient_id),
  CONSTRAINT fk_app_doctor FOREIGN KEY (doctor_id) REFERENCES doctor(doctor_id)
) ENGINE=InnoDB;

CREATE TABLE admission (
  admission_id INT AUTO_INCREMENT PRIMARY KEY,
  patient_id INT NOT NULL,
  bed_id INT,
  admitting_doctor_id INT,
  admission_date DATETIME DEFAULT CURRENT_TIMESTAMP,
  discharge_date DATETIME,
  status ENUM('Admitted','Discharged','Transferred') DEFAULT 'Admitted',
  notes TEXT,
  CONSTRAINT fk_adm_patient FOREIGN KEY (patient_id) REFERENCES patient(patient_id),
  CONSTRAINT fk_adm_bed FOREIGN KEY (bed_id) REFERENCES bed(bed_id),
  CONSTRAINT fk_adm_doc FOREIGN KEY (admitting_doctor_id) REFERENCES doctor(doctor_id)
) ENGINE=InnoDB;

CREATE TABLE treatment (
  treatment_id INT AUTO_INCREMENT PRIMARY KEY,
  admission_id INT,
  appointment_id INT,
  performed_by_doctor_id INT,
  description TEXT,
  cost DECIMAL(10,2) DEFAULT 0,
  performed_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_treat_adm FOREIGN KEY (admission_id) REFERENCES admission(admission_id),
  CONSTRAINT fk_treat_app FOREIGN KEY (appointment_id) REFERENCES appointment(appointment_id),
  CONSTRAINT fk_treat_doc FOREIGN KEY (performed_by_doctor_id) REFERENCES doctor(doctor_id)
) ENGINE=InnoDB;

CREATE TABLE prescription (
  prescription_id INT AUTO_INCREMENT PRIMARY KEY,
  appointment_id INT,
  admission_id INT,
  prescribed_by_doctor_id INT,
  notes TEXT,
  issued_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_pres_app FOREIGN KEY (appointment_id) REFERENCES appointment(appointment_id),
  CONSTRAINT fk_pres_adm FOREIGN KEY (admission_id) REFERENCES admission(admission_id),
  CONSTRAINT fk_pres_doc FOREIGN KEY (prescribed_by_doctor_id) REFERENCES doctor(doctor_id)
) ENGINE=InnoDB;

CREATE TABLE prescription_line (
  line_id INT AUTO_INCREMENT PRIMARY KEY,
  prescription_id INT NOT NULL,
  medicine_name VARCHAR(200) NOT NULL,
  dosage VARCHAR(100),
  frequency VARCHAR(100),
  duration VARCHAR(50),
  notes TEXT,
  CONSTRAINT fk_pl_pres FOREIGN KEY (prescription_id) REFERENCES prescription(prescription_id)
) ENGINE=InnoDB;

CREATE TABLE invoice (
  invoice_id INT AUTO_INCREMENT PRIMARY KEY,
  patient_id INT NOT NULL,
  admission_id INT,
  appointment_id INT,
  issued_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  total_amount DECIMAL(12,2) DEFAULT 0,
  paid_amount DECIMAL(12,2) DEFAULT 0,
  status ENUM('Unpaid','Partially Paid','Paid') DEFAULT 'Unpaid',
  CONSTRAINT fk_inv_patient FOREIGN KEY (patient_id) REFERENCES patient(patient_id),
  CONSTRAINT fk_inv_adm FOREIGN KEY (admission_id) REFERENCES admission(admission_id),
  CONSTRAINT fk_inv_app FOREIGN KEY (appointment_id) REFERENCES appointment(appointment_id)
) ENGINE=InnoDB;

CREATE TABLE invoice_line (
  line_id INT AUTO_INCREMENT PRIMARY KEY,
  invoice_id INT NOT NULL,
  description VARCHAR(255) NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  CONSTRAINT fk_il_invoice FOREIGN KEY (invoice_id) REFERENCES invoice(invoice_id)
) ENGINE=InnoDB;

INSERT INTO department (name, description) VALUES
('General Medicine','General medical care'),
('Cardiology','Heart related');

INSERT INTO doctor (first_name,last_name,department_id,phone,email,specialization)
VALUES
('Amit','Kumar',1,'+91-9000000001','amit.k@example.com','General Physician'),
('Sana','Shah',2,'+91-9000000002','sana.s@example.com','Cardiologist');

INSERT INTO patient (first_name,last_name,dob,gender,phone,email,address)
VALUES
('Ravi','Patel','1985-03-22','M','+91-9999999991','ravi.p@example.com','Ahmedabad'),
('Meera','Das','1990-09-10','F','+91-9999999992','meera.d@example.com','Bengaluru');

INSERT INTO room (room_no,floor,type) VALUES
('R101',1,'General'),
('R201',2,'ICU');

INSERT INTO bed (room_id,bed_no) VALUES
(1,'B1'),
(1,'B2'),
(2,'B1');

INSERT INTO appointment (patient_id,doctor_id,appointment_datetime,reason)
VALUES
(1,1,'2025-11-20 10:00:00','Fever and cough');

INSERT INTO admission (patient_id,bed_id,admitting_doctor_id,admission_date,status,notes)
VALUES
(2,3,2,'2025-11-10 14:00:00','Admitted','High BP and chest pain');

INSERT INTO treatment (admission_id,performed_by_doctor_id,description,cost)
VALUES
(1,2,'ECG and observation',1500.00);

INSERT INTO invoice (patient_id,admission_id,issued_at,total_amount,paid_amount,status)
VALUES
(2,1,NOW(),1500.00,0.00,'Unpaid');

INSERT INTO invoice_line (invoice_id,description,amount)
VALUES
(1,'ECG',1500.00);

DELIMITER $$
CREATE PROCEDURE admit_patient(
  IN p_patient_id INT,
  IN p_bed_id INT,
  IN p_doctor_id INT,
  IN p_notes TEXT
)
BEGIN
  INSERT INTO admission(patient_id, bed_id, admitting_doctor_id, admission_date, status, notes)
  VALUES (p_patient_id, p_bed_id, p_doctor_id, NOW(), 'Admitted', p_notes);
  UPDATE bed SET status = 'Occupied' WHERE bed_id = p_bed_id;
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE discharge_patient(IN p_admission_id INT)
BEGIN
  UPDATE admission
    SET discharge_date = NOW(), status = 'Discharged'
    WHERE admission_id = p_admission_id;
  UPDATE bed b
    JOIN admission a ON b.bed_id = a.bed_id
    SET b.status = 'Available'
    WHERE a.admission_id = p_admission_id;
END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER trg_invoice_after_insert
AFTER INSERT ON invoice_line
FOR EACH ROW
BEGIN
  UPDATE invoice SET total_amount = (SELECT IFNULL(SUM(amount),0) FROM invoice_line WHERE invoice_id = NEW.invoice_id)
  WHERE invoice_id = NEW.invoice_id;
END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER trg_check_appointment BEFORE INSERT ON appointment
FOR EACH ROW
BEGIN
  IF (SELECT COUNT(*) FROM appointment WHERE doctor_id = NEW.doctor_id AND ABS(TIMESTAMPDIFF(MINUTE, appointment_datetime, NEW.appointment_datetime)) < 30) > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Doctor already has an appointment around this time';
  END IF;
END$$
DELIMITER ;

CREATE INDEX idx_appointment_doctor_dt ON appointment(doctor_id, appointment_datetime);
CREATE INDEX idx_admission_status ON admission(status);
CREATE INDEX idx_invoice_issued_at ON invoice(issued_at);

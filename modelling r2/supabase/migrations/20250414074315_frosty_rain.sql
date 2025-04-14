/*
  # Medical Center Database Schema

  1. New Tables
    - doctors
      - id (uuid, primary key)
      - name (text)
      - specialty (text)
      - created_at (timestamp)
    
    - patients
      - id (uuid, primary key)
      - name (text)
      - date_of_birth (date)
      - created_at (timestamp)
    
    - diseases
      - id (uuid, primary key)
      - name (text)
      - description (text)
      - created_at (timestamp)
    
    - visits
      - id (uuid, primary key)
      - doctor_id (uuid, foreign key)
      - patient_id (uuid, foreign key)
      - visit_date (timestamp)
      - notes (text)
      - created_at (timestamp)
    
    - visit_diagnoses
      - id (uuid, primary key)
      - visit_id (uuid, foreign key)
      - disease_id (uuid, foreign key)
      - created_at (timestamp)

  2. Security
    - Enable RLS on all tables
    - Add policies for authenticated users
*/

-- Create doctors table
CREATE TABLE IF NOT EXISTS doctors (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  specialty text,
  created_at timestamptz DEFAULT now()
);

-- Create patients table
CREATE TABLE IF NOT EXISTS patients (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  date_of_birth date NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Create diseases table
CREATE TABLE IF NOT EXISTS diseases (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text,
  created_at timestamptz DEFAULT now()
);

-- Create visits table
CREATE TABLE IF NOT EXISTS visits (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  doctor_id uuid REFERENCES doctors(id) ON DELETE CASCADE,
  patient_id uuid REFERENCES patients(id) ON DELETE CASCADE,
  visit_date timestamptz NOT NULL DEFAULT now(),
  notes text,
  created_at timestamptz DEFAULT now()
);

-- Create visit_diagnoses table (junction table for visits and diseases)
CREATE TABLE IF NOT EXISTS visit_diagnoses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  visit_id uuid REFERENCES visits(id) ON DELETE CASCADE,
  disease_id uuid REFERENCES diseases(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  UNIQUE(visit_id, disease_id)
);

-- Enable Row Level Security
ALTER TABLE doctors ENABLE ROW LEVEL SECURITY;
ALTER TABLE patients ENABLE ROW LEVEL SECURITY;
ALTER TABLE diseases ENABLE ROW LEVEL SECURITY;
ALTER TABLE visits ENABLE ROW LEVEL SECURITY;
ALTER TABLE visit_diagnoses ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Allow authenticated users to read doctors"
  ON doctors
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow authenticated users to read patients"
  ON patients
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow authenticated users to read diseases"
  ON diseases
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow authenticated users to read visits"
  ON visits
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow authenticated users to read visit_diagnoses"
  ON visit_diagnoses
  FOR SELECT
  TO authenticated
  USING (true);

-- Insert sample data
INSERT INTO doctors (name, specialty) VALUES
  ('Dr. Smith', 'Cardiology'),
  ('Dr. Johnson', 'Pediatrics'),
  ('Dr. Williams', 'Neurology');

INSERT INTO patients (name, date_of_birth) VALUES
  ('John Doe', '1980-01-15'),
  ('Jane Smith', '1992-05-20'),
  ('Bob Wilson', '1975-11-30');

INSERT INTO diseases (name, description) VALUES
  ('Hypertension', 'High blood pressure'),
  ('Common Cold', 'Viral upper respiratory tract infection'),
  ('Type 2 Diabetes', 'Metabolic disorder affecting blood sugar levels');

-- Create some visits
INSERT INTO visits (doctor_id, patient_id, visit_date, notes)
SELECT 
  d.id,
  p.id,
  now() - interval '1 day',
  'Regular checkup'
FROM doctors d, patients p
WHERE d.name = 'Dr. Smith' AND p.name = 'John Doe';

-- Add diagnoses to visits
INSERT INTO visit_diagnoses (visit_id, disease_id)
SELECT 
  v.id,
  d.id
FROM visits v, diseases d
WHERE d.name = 'Hypertension'
LIMIT 1;
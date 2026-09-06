# OULAD Dimensional Model

A data engineering project using the **Open University Learning Analytics Dataset (OULAD)** to build a structured and reliable data pipeline for learning analytics.

## Objective

The project focuses on ingesting, cleaning, transforming, and modeling OULAD data using a **Medallion Architecture**.

## Architecture

**Bronze → Silver → Gold**

- **Bronze** – Raw OULAD datasets ingested with minimal transformation.
- **Silver** – Cleaned, validated, and standardized data.
- **Gold** – Analytics-ready tables designed for reporting and analysis.

## Dataset

<img width="828" height="342" alt="image" src="https://github.com/user-attachments/assets/c2bc4868-86f6-4cf1-bf74-606922080263" />

##### Source: Kuzilek et al. (2017)

The OULAD dataset contains information about students, courses, assessments, registrations, and interactions with the Virtual Learning Environment (VLE).

Key datasets include:

- `studentInfo`
- `studentRegistration`
- `studentAssessment`
- `studentVle`
- `assessments`
- `courses`
- `vle`
- `student`

## Data Engineering Workflow

```text
OULAD CSV Files (CloudFlare R2)
      ↓
   Bronze
      ↓
Data Cleaning and Validation
      ↓
   Silver
      ↓
Transformations and Data Modeling
      ↓
    Gold
      ↓
Analytics / Reporting

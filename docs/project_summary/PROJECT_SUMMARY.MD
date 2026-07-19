# PROJECT_SUMMARY.md

# HydroDok

**HydroDok** is a digital hydroponic farm management platform designed for the Pamahalaang Lungsod ng General Trias Cavite, Malabon Agricultural Center. The system streamlines farm operations, improves communication between farmers and administrators, and provides a direct Farmer-to-Consumer (F2C) marketplace.

The project consists of a cross-platform mobile application built with Flutter and a cloud backend powered by Supabase. Interactive farm mapping is implemented using MapTiler.

---

## Objectives

- Digitize hydroponic farm management.
- Replace manual logbooks and whiteboard tracking.
- Improve communication between farmers and agricultural staff.
- Increase market visibility of local hydroponic farms.
- Provide a centralized platform for monitoring and reporting.

---

# Technology Stack

## Frontend

- Flutter
- Dart
- Material 3

## Backend

- Supabase
    - Authentication
    - PostgreSQL Database
    - Storage
    - Realtime
    - Edge Functions (optional)

## Mapping

- MapTiler SDK
- MapTiler Geocoding API

---

# Core Features

## Authentication

- Farmer Login
- Consumer Login
- Administrator Login
- Role-Based Access Control (RBAC)

---

## Task Scheduling

- Create farm tasks
- Nutrient schedule
- Watering reminders
- Task completion tracking

---

## Nutrient Log

- Record nutrient applications
- Historical logs
- Daily monitoring

---

## Issue Reporting

- Submit farm issues
- Upload photos
- Admin review
- Resolution status tracking

---

## Pest Identification Catalog

- Manual pest browsing
- Symptoms
- Causes
- Recommended treatments

---

## Farm Mapping

- Register farm location
- Interactive map
- View hydroponic farms
- Farm information

Powered by **MapTiler**

---

## Farmer-to-Consumer Marketplace

- Product listings
- Inventory management
- Product availability
- Direct farmer contact

---

## Batch Pooling

- Combine harvests
- Pool management
- Consolidated deliveries

---

## Community Forum

- Discussion boards
- Knowledge sharing
- Farmer collaboration

---

# User Roles

## Farmer

- Manage farm tasks
- Submit reports
- Update nutrient logs
- Manage products
- Join batch pools
- Participate in discussions

---

## Consumer

- Browse marketplace
- View farms
- Contact farmers
- Purchase products

---

## Administrator

- Manage users
- Review issue reports
- Manage marketplace listings
- Monitor farms
- Moderate community
- View analytics

---

# Database (Supabase)

Main tables include:

- users
- profiles
- farms
- farm_locations
- tasks
- nutrient_logs
- issue_reports
- pest_catalog
- products
- inventory
- orders
- batch_pools
- batch_members
- forum_posts
- forum_comments
- notifications

---

# Authentication

Supabase Auth

- Email & Password
- Role-based permissions
- Session management

---

# File Storage

Supabase Storage

Used for:

- Issue report images
- Product images
- User profile pictures

---

# Notifications

Realtime notifications for:

- New issue reports
- Marketplace updates
- Batch pooling invitations
- Community replies
- Task reminders

---

# System Architecture

Flutter Mobile App
│
▼
Supabase Backend
│
├── PostgreSQL
├── Authentication
├── Storage
├── Realtime
└── Edge Functions
│
▼
MapTiler Services
│
▼
Interactive Farm Maps

---

# Expected Benefits

- Paperless farm management
- Faster issue resolution
- Better communication
- Increased farmer visibility
- Improved product marketing
- Centralized agricultural monitoring

---

# Development Methodology

Agile Scrum

Sprint-based development with iterative improvements through continuous feedback from farmers and Agricultural Center staff.

---

# Target Platform

- Android
- iOS

---

# Tech Stack Summary

| Category | Technology |
|----------|------------|
| Mobile | Flutter |
| Language | Dart |
| Backend | Supabase |
| Database | PostgreSQL |
| Authentication | Supabase Auth |
| Storage | Supabase Storage |
| Realtime | Supabase Realtime |
| Maps | MapTiler |
| State Management | Riverpod |
| Architecture | Clean Architecture |
| Version Control | Git + GitHub |

---

HydroDok aims to modernize hydroponic farm management by providing an integrated mobile platform that combines farm monitoring, issue reporting, geolocation, marketplace functionality, and community collaboration into a single software solution for farmers, consumers, and agricultural administrators.
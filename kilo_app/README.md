# kilo_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

# KI-LO: Asistente de Entrenamiento Personal 🏋️‍♂️🔥

![Logo KI-LO](assets/images/logo_kilo.png)

[cite_start]**KI-LO** es una aplicación móvil desarrollada con **Flutter** y **Firebase**, diseñada para centralizar el seguimiento del progreso físico de usuarios de gimnasio.[cite_start]El proyecto combina un registro intuitivo de entrenamientos con un sistema de gamificación y cálculos metabólicos avanzados.
---

## 🚀 Funcionalidades Principales

* [cite_start]**Gestión de Identidad**: Registro e inicio de sesión seguro mediante Firebase Authentication.
* [cite_start]**Seguimiento Biométrico**: Registro de peso, altura y edad con cálculo automático de la **Tasa Metabólica Basal (TMB)** mediante la fórmula de Harris-Benedict. 
* [cite_start]**Sistema de Gamificación**: Visualización de "Rachas" para fomentar la constancia del usuario (estilo Duolingo). 
* **Dashboard Personalizado**: Interfaz dinámica con cambio de temas de color y nombre de usuario sincronizados en la nube.
* [cite_start]**Generación de Rutinas (IA)**: Módulo en desarrollo para la creación de planes de entrenamiento adaptativos utilizando la API de Google Gemini. 

---

## 🛠️ Stack Tecnológico

* [cite_start]**Frontend**: [Flutter](https://flutter.dev/) (Dart) 
* [cite_start]**Backend**: [Firebase](https://firebase.google.com/) (BaaS) 
* [cite_start]**Base de Datos**: Cloud Firestore (NoSQL) 
* [cite_start]**Autenticación**: Firebase Auth 
* [cite_start]**Arquitectura**: Clean Architecture (Capa de presentación, dominio y datos).

---

## 📦 Instalación y Configuración

1.  **Clonar el repositorio**:
    ```bash
    git clone [https://github.com/kralexby/tfg_app.git](https://github.com/kralexby/tfg_app.git)
    ```
2.  **Instalar dependencias**:
    ```bash
    flutter pub get
    ```
3.  **Configurar Firebase**:
    * Crea un proyecto en [Firebase Console](https://console.firebase.google.com/).
    * Añade las aplicaciones Android/iOS.
    * Descarga y añade los archivos de configuración (`google-services.json` / `GoogleService-Info.plist`).
4.  **Ejecutar la app**:
    ```bash
    flutter run
    ```

---

## Autor
* [cite_start]**Alejandro Fernández Ripoll** - [kralexby](https://github.com/kralexby) 
* [cite_start]Proyecto Fin de Grado - Ciclo DAM (2025/2026).
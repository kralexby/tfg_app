# KI-LO: Asistente de Entrenamiento Personal 

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Google Gemini](https://img.shields.io/badge/Google%20Gemini-8E75B2?style=for-the-badge&logo=google&logoColor=white)

![Logo KI-LO](assets/images/logo_kilo.png)

KI-LO es una aplicación móvil desarrollada con Flutter y Firebase, diseñada para centralizar el seguimiento del progreso físico de usuarios de gimnasio. El proyecto combina un registro intuitivo de entrenamientos con un sistema de gamificación y cálculos metabólicos avanzados.

---

## ✨ Funcionalidades Principales

* 🔐 Gestión de Identidad: Registro e inicio de sesión seguro mediante Firebase Authentication.
* 🤖 Generación de Rutinas (IA): Módulo inteligente que analiza métricas, objetivos y lesiones para devolver rutinas completas en formato JSON estricto.
* 📋 Workout Logger (Gestión Manual): Creación de rutinas personalizadas y registro activo de series, repeticiones y kilogramos levantados.
* 🧮 Seguimiento Biométrico: Registro de métricas con cálculo automático de la Tasa Metabólica Basal (TMB) mediante la fórmula de Harris-Benedict. 
* 🔥 Sistema de Gamificación: Calendario dinámico y sistema de "Rachas" (días entrenados) que se actualiza tras cada sesión para fomentar la constancia. 

---

## 🛠️ Stack Tecnológico

* Frontend: [Flutter](https://flutter.dev/) (Dart) 
* Backend: [Firebase](https://firebase.google.com/) (BaaS) 
* Base de Datos: Cloud Firestore (NoSQL) 
* Autenticación: Firebase Auth 
* Arquitectura: Arquitectura Modular Reactiva.

---

## 📦 Instalación y Configuración

1.  Clonar el repositorio:
    ```bash
    git clone [https://github.com/kralexby/tfg_app.git](https://github.com/kralexby/tfg_app.git)
    ```
2.  Instalar dependencias:
    ```bash
    flutter pub get
    ```
3.  Configurar Firebase:
    * Asegúrate de tener los archivos de configuración de Firebase (`google-services.json` para Android / `GoogleService-Info.plist` para iOS) en sus respectivas carpetas nativas.
4.  Configurar Variables de Entorno (IMPORTANTE):
    * Crea un archivo llamado `.env` en la raíz del proyecto.
    * Añade tu clave de API de Google Gemini:
      ```env
      GEMINI_API_KEY=tu_clave_api_aqui
      ```
5.  Ejecutar la app:
    ```bash
    flutter run
    ```

---

## 👨‍💻 Autor
* Alejandro Fernández Ripoll - [@kralexby](https://github.com/kralexby) 
* Proyecto Fin de Grado - Ciclo Superior DAM (2025/2026).
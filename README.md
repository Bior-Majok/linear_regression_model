# Under-5 Child Mortality Prediction in Africa

## 1. Mission and Problem
With Umoja Health Connect, my mission is to improve access to essential health services for underserved communities across Africa. The problem I address is the high rate of under-5 child mortality caused by disparities in immunization coverage, clean water, sanitation, and healthcare financing. This machine learning application predicts national under-5 mortality rates (deaths per 1,000 live births) to help health ministry analysts and program planners prioritize interventions where needs are greatest.

## 2. Dataset Description and Source
The model is trained on a rich panel dataset of African nations sourced from Mendeley Data:
* **Dataset:** [Replication Data and Code for "Urban Services, Health Systems, and Under-Five Mortality Risk in Africa: A Machine Learning Classification Approach"](https://doi.org/10.17632/bz4xfzm8jz.1) (Dawson-Amoah & de-Graft, 2026; DOI: `10.17632/bz4xfzm8jz.1`).
* **Volume and Variety:** Contains 2,160 country-year observations across Africa with 21 indicators covering demographics, public infrastructure, economic output, and healthcare services.
* **Engineered Features:** After exploratory data analysis, dropping collinear/irrelevant columns (such as duplicate IDs, loan types, and maternal mortality), 11 indicators were selected for modeling:
  1. `subregion` (Categorical: Central, Eastern, Northern, Southern, Western Africa)
  2. `income_level` (Categorical: Low income, Lower middle income, Upper middle income, High income)
  3. `urban_pop_pct` (Urban population as % of total)
  4. `urban_growth` (Annual urban population growth rate %)
  5. `sanitation_pct` (% of population using basic sanitation services)
  6. `water_pct` (% of population using basic drinking water services)
  7. `electricity_pct` (% of population with electricity access)
  8. `health_exp_per_capita` (Current health expenditure per capita in current US$)
  9. `dpt_immunization` (% of children ages 12–23 months vaccinated against DPT)
  10. `gdp_per_capita` (GDP per capita in constant 2015 US$)
  11. `primary_completion` (Primary school completion rate %)
* **Target Variable:** `u5_mortality` (Under-5 mortality rate per 1,000 live births).

## 3. Public Swagger UI Documentation
* **Live API URL:** [https://linear-regression-model-p51l.onrender.com/docs](https://linear-regression-model-p51l.onrender.com/docs)
* **Alternative root health check:** [https://linear-regression-model-p51l.onrender.com/](https://linear-regression-model-p51l.onrender.com/)

*(Note: Hosted on Render's free tier. If the service is idling, the first request may take 30 to 60 seconds to spin up).*

## 4. Video Demonstration Link
* **YouTube Demo (Task 4):** [https://youtu.be/OCUFnqPzLuI](https://youtu.be/OCUFnqPzLuI)

*(Demo includes: mobile app on Android emulator, code walkthrough of API integration, Swagger UI validation and retraining tests, notebook model evaluation and loss curves, and answers to the four required technical questions).*

## 5. Step-by-Step Instructions to Run the Mobile App

### Prerequisites
* Flutter SDK (version 3.19.0 or higher)
* Android Studio with an Android Virtual Device (AVD, e.g. Pixel 4a / API 34), or a physical Android/iOS device
* Git and Python 3.11+ (if running the backend API locally)

### Steps to Run

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Bior-Majok/linear_regression_model.git
   cd linear_regression_model
   ```

2. **Navigate to the Flutter application:**
   ```bash
   cd summative/FlutterApp
   ```

3. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```

4. **Start your emulator or connect your phone:**
   * Open Android Studio -> Device Manager -> Launch your emulator (e.g., Pixel 4a).
   * Verify Flutter recognizes the device:
     ```bash
     flutter devices
     ```

5. **Run the application:**
   ```bash
   flutter run
   ```

6. **Using the App:**
   * **API Endpoint:** By default, the top configuration card has quick-select chips:
     * **Use Render URL:** Connects to the public live Render API (`https://linear-regression-model-p51l.onrender.com/predict`).
     * **Use Android Emulator (10.0.2.2):** Connects to a locally running FastAPI instance (`http://10.0.2.2:8000/predict`).
   * **Quick Test:** Tap **"Load Sample Data"** to automatically populate realistic test values across all 11 indicators.
   * **Predict:** Tap the green **"Predict"** button. The predicted under-5 mortality rate will appear in the output display area.
   * **Error Validation:** Tap **"Clear Form"** or enter an invalid value (e.g., text in a numeric field) and tap **"Predict"** to view client-side and server-side validation error handling.

---

### (Optional) Running the FastAPI Backend Locally
If you want to run the prediction server locally instead of using Render:
```bash
cd summative/API
pip install -r requirements.txt
python -m uvicorn prediction:app --host 0.0.0.0 --port 8000 --reload
```
Access the local Swagger UI at [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs).

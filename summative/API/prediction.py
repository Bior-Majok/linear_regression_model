"""
FastAPI service for under-5 child mortality prediction in Africa.
Part of the Umoja Health Connect project.
"""

import io
from contextlib import asynccontextmanager
from pathlib import Path
from typing import Dict, Any

import joblib
import pandas as pd
from fastapi import FastAPI, File, HTTPException, UploadFile, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

# File paths
CURRENT_DIR = Path(__file__).resolve().parent
MODEL_PATH = CURRENT_DIR / "best_model.pkl"

def find_original_data_path() -> Path:
    """Finds africa_child_mortality.csv across possible working directories."""
    candidates = [
        CURRENT_DIR.parent / "linear_regression" / "africa_child_mortality.csv",
        CURRENT_DIR / "africa_child_mortality.csv",
        Path("linear_regression/africa_child_mortality.csv"),
        Path("../linear_regression/africa_child_mortality.csv"),
    ]
    for p in candidates:
        if p.exists():
            return p
    raise FileNotFoundError("Could not find africa_child_mortality.csv")


# Pydantic schema enforcing data types and realistic physical/economic bounds.
# Any missing, mistyped, or out-of-range value returns a 422 validation error.
class ChildMortalityFeatures(BaseModel):
    subregion: str = Field(..., description="Geographic subregion in Africa")
    income_level: str = Field(..., description="World Bank income classification")
    urban_pop_pct: float = Field(..., ge=0.0, le=100.0, description="Urban population percentage")
    urban_growth: float = Field(..., ge=-20.0, le=50.0, description="Annual urban growth rate percentage")
    sanitation_pct: float = Field(..., ge=0.0, le=100.0, description="Basic sanitation access percentage")
    water_pct: float = Field(..., ge=0.0, le=100.0, description="Basic drinking water access percentage")
    electricity_pct: float = Field(..., ge=0.0, le=100.0, description="Electricity access percentage")
    health_exp_per_capita: float = Field(..., ge=0.0, le=5000.0, description="Health expenditure per capita in US$")
    dpt_immunization: float = Field(..., ge=0.0, le=100.0, description="DPT immunization percentage (ages 12-23 months)")
    gdp_per_capita: float = Field(..., ge=0.0, le=100000.0, description="GDP per capita in constant 2015 US$")
    primary_completion: float = Field(..., ge=0.0, le=200.0, description="Primary school completion rate percentage")

    model_config = {
        "json_schema_extra": {
            "example": {
                "subregion": "East Africa",
                "income_level": "Low income",
                "urban_pop_pct": 25.5,
                "urban_growth": 4.1,
                "sanitation_pct": 32.0,
                "water_pct": 58.0,
                "electricity_pct": 45.0,
                "health_exp_per_capita": 42.5,
                "dpt_immunization": 82.0,
                "gdp_per_capita": 850.0,
                "primary_completion": 68.0
            }
        }
    }


def load_saved_model():
    """Loads the trained model pipeline from disk."""
    if not MODEL_PATH.exists():
        raise RuntimeError(f"Model file not found at {MODEL_PATH}")
    return joblib.load(MODEL_PATH)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Ensures the model is loaded when the app starts up."""
    if not hasattr(app.state, "model") or app.state.model is None:
        app.state.model = load_saved_model()
    yield


app = FastAPI(
    title="Umoja Health Connect - Child Mortality Prediction API",
    description="Serves a regression model predicting under-5 child mortality per 1,000 live births in Africa.",
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url=None
)

# Load model into application state
app.state.model = load_saved_model()

# CORS configuration:
# I allow my deployed Render URL and local web debug hosts so Swagger UI and local web apps can call the API.
# I restrict origins by avoiding '*' so random third-party sites cannot trigger predictions or retraining.
# I also restrict methods to GET, POST, and OPTIONS, and allow standard headers and credentials.
# Mobile apps (Flutter on emulator/phone) are native clients and ignore CORS, so this only restricts browser traffic.
allowed_origins = [
    "https://linear-regression-model-api.onrender.com",
    "http://localhost",
    "http://localhost:8000",
    "http://localhost:3000",
    "http://localhost:8080",
    "http://127.0.0.1",
    "http://127.0.0.1:8000",
    "http://127.0.0.1:3000",
    "http://127.0.0.1:8080",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials=True,
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["Content-Type", "Authorization", "Accept", "X-Requested-With"],
)

COLUMN_RENAME_MAP = {
    "Mortality rate, under-5 (per 1,000 live births)": "u5_mortality",
    "Urban population (% of total population)": "urban_pop_pct",
    "Urban population growth (annual %)": "urban_growth",
    "People using at least basic sanitation services (% of population)": "sanitation_pct",
    "People using at least basic drinking water services (% of population)": "water_pct",
    "Access to electricity (% of population)": "electricity_pct",
    "Current health expenditure per capita (current US$)": "health_exp_per_capita",
    "Immunization, DPT (% of children ages 12-23 months)": "dpt_immunization",
    "Immunization, measles (% of children ages 12-23 months)": "measles_immunization",
    "GDP per capita (constant 2015 US$)": "gdp_per_capita",
    "Primary completion rate, total (% of relevant age group)": "primary_completion",
    "Maternal mortality ratio (modeled estimate, per 100,000 live births)": "maternal_mortality",
}

FEATURE_COLUMNS = [
    "subregion",
    "income_level",
    "urban_pop_pct",
    "urban_growth",
    "sanitation_pct",
    "water_pct",
    "electricity_pct",
    "health_exp_per_capita",
    "dpt_immunization",
    "gdp_per_capita",
    "primary_completion"
]

def load_clean_training_data() -> pd.DataFrame:
    """Loads and cleans original data using the same drops chosen in the notebook."""
    df = pd.read_csv(find_original_data_path()).rename(columns=COLUMN_RENAME_MAP)
    drop_cols = ["continent", "iso3", "income_level_id", "wb_region", "lending_type",
                 "year", "maternal_mortality", "measles_immunization", "country"]
    return df.drop(columns=[c for c in drop_cols if c in df.columns])


@app.get("/", tags=["Info"])
def root() -> Dict[str, Any]:
    """Basic health check."""
    regressor = app.state.model.named_steps["regressor"]
    return {
        "mission": "Umoja Health Connect",
        "service": "Under-5 Child Mortality Prediction API",
        "model_deployed": type(regressor).__name__,
        "documentation": "/docs",
        "status": "healthy"
    }


@app.post("/predict", tags=["Prediction"])
def predict(features: ChildMortalityFeatures) -> Dict[str, Any]:
    """Predicts under-5 mortality rate from the 11 validated indicators."""
    if not hasattr(app.state, "model") or app.state.model is None:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Model is not loaded."
        )

    # Pass the validated inputs to the pipeline as a single row dataframe
    input_data = pd.DataFrame([features.model_dump()])

    try:
        prediction = app.state.model.predict(input_data)[0]
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Inference error: {str(exc)}"
        )

    regressor = app.state.model.named_steps["regressor"]
    return {
        "predicted_u5_mortality": round(float(prediction), 2),
        "unit": "deaths per 1,000 live births",
        "model_used": type(regressor).__name__
    }


@app.post("/retrain", tags=["Retraining"])
async def retrain(file: UploadFile = File(...)) -> Dict[str, Any]:
    """Retrains the model with newly uploaded CSV data and updates it in memory."""
    if not file.filename.endswith(".csv"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Uploaded file must be a CSV (.csv)."
        )

    try:
        content = await file.read()
        new_df = pd.read_csv(io.StringIO(content.decode("utf-8")))
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Failed to read CSV: {str(exc)}"
        )

    new_df = new_df.rename(columns=COLUMN_RENAME_MAP)

    if "u5_mortality" not in new_df.columns:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="CSV is missing the target column 'u5_mortality'."
        )

    missing_features = [c for c in FEATURE_COLUMNS if c not in new_df.columns]
    if missing_features:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"CSV is missing features: {missing_features}"
        )

    try:
        orig_df = load_clean_training_data()
        cols = FEATURE_COLUMNS + ["u5_mortality"]
        combined_df = pd.concat([orig_df[cols], new_df[cols]], ignore_index=True)

        X_combined = combined_df[FEATURE_COLUMNS]
        y_combined = combined_df["u5_mortality"]

        # Refit pipeline and save to disk
        app.state.model.fit(X_combined, y_combined)
        joblib.dump(app.state.model, MODEL_PATH)

    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Retraining failed: {str(exc)}"
        )

    regressor = app.state.model.named_steps["regressor"]
    return {
        "status": "success",
        "message": "Model retrained and updated in-memory successfully.",
        "original_rows": len(orig_df),
        "new_rows_added": len(new_df),
        "total_training_rows": len(combined_df),
        "model_type": type(regressor).__name__
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("prediction:app", host="0.0.0.0", port=8000, reload=True)

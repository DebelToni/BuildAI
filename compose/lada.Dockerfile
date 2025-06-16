FROM python:3.11-slim
WORKDIR /app
COPY LADA/requirements.txt .
RUN pip install -r requirements.txt
COPY LADA/ .
EXPOSE 5000
CMD ["gunicorn", "lada.app:app", "-b", "0.0.0.0:5000", "--workers", "2"]

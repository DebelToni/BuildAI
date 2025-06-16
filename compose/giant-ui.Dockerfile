FROM python:3.11-slim
WORKDIR /app
COPY SUPER-GIANT/ui/requirements.txt .
RUN pip install -r requirements.txt
COPY SUPER-GIANT/ui/ .
EXPOSE 5001
CMD ["gunicorn", "ui.app:app", "-b", "0.0.0.0:5001", "--workers", "2"]


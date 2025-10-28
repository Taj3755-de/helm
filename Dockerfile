# Base image
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Copy code
COPY app/ /app/

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Environment variable
ENV ENV=staging

# Expose port
EXPOSE 5000

# Run the app
CMD ["python", "app.py"]

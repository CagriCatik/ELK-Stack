FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt pyproject.toml ./
RUN pip install --no-cache-dir -r requirements.txt

COPY xml_insight_lab ./xml_insight_lab
COPY tests ./tests
RUN pip install --no-cache-dir --no-deps -e .

ENV PYTHONUNBUFFERED=1
ENTRYPOINT ["xml-insight"]

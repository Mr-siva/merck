FROM python:3.12-slim
RUN useradd -r -u 10001 hello
COPY app/server.py /app/server.py
USER hello
ENV PORT=8080
EXPOSE 8080
CMD ["python", "/app/server.py"]

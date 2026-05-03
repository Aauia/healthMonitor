import requests

r = requests.post("http://127.0.0.1:8000/auth/login", data={"username": "test@test.com", "password": "password"})
print(r.status_code, r.text)


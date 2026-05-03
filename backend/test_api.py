import requests

try:
    r_login = requests.post("http://127.0.0.1:8080/auth/login", data={"username": "test@test.com", "password": "password"})
    if r_login.status_code == 200:
        token = r_login.json()["access_token"]
        r_supp = requests.get("http://127.0.0.1:8080/supplements/my", headers={"Authorization": f"Bearer {token}"})
        print(r_supp.text)
    else:
        print("Login failed", r_login.status_code, r_login.text)
except Exception as e:
    print(e)

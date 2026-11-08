from app import create_app

app = create_app()

if __name__ == "__main__":
    # Development only. For Windows LAN use, see README.md and Waitress instructions.
    # Keep loopback-only by default; opt into LAN binding deliberately via .env.
    import os
    host = os.getenv("EGMIS_HOST", "127.0.0.1")
    port = int(os.getenv("EGMIS_PORT", "5000"))
    app.run(host=host, port=port, debug=False)

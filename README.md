# LibreBooking Demo

Welcome to the **LibreBooking Demo**, a public, auto-resetting instance of [LibreBooking](https://github.com/LibreBooking/app) — an open-source room and resource scheduling system.

This demo instance is ideal for evaluating the app without any setup on your machine.

---

## 🔐 Login Credentials

Use the following accounts to try the system:

| Role   | Username | Password     |
|--------|----------|--------------|
| Admin  | `admin`  | `demoadmin`  |
| User   | `user`   | `demouser`   |

You can switch languages, test user features, or access the full admin panel.

---

## 🔄 How the Demo Works

- The instance is deployed via Docker and hosted on [Fly.io](https://fly.io)
- A cron job resets:
  - the **database** (from a `.sql` dump)
  - the **configuration file** (`config.php`)
- A timestamp file tracks reset intervals

Reset logic is handled by `/setup/reset-container.sh`

These variables are defined in [`fly.toml`](./fly.toml) and passed to the container on deploy.

| Variable              | Required | Source     | Description                                                          |
| --------------------- | -------- | ---------- | -------------------------------------------------------------------- |
| `LB_SCRIPT_URL`       | ✅ Yes    | `fly.toml` | Full public URL to the LibreBooking `/Web` directory                 |
| `RESET_AFTER_SECONDS` | ❌ No     | `fly.toml` | Time in seconds before demo auto-reset. Defaults to `7200` (2 hours) |
| `LB_DATABASE_NAME`          | ❌ No     | `fly.toml` | Database name. Defaults to `librebooking`                            |
| `LB_DATABASE_USER`          | ❌ No     | `fly.toml` | Database username. Defaults to `librebooking`                        |
| `PASSWORD`      | ❌ No     | **secret** | Database user password. Auto-generated if unset at runtime           |
| `LB_DATABASE_HOSTSPEC`          | ❌ No     | `fly.toml` | Hostname of the database (e.g., `127.0.0.1`)                         |

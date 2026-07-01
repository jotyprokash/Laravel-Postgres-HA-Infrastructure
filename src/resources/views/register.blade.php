<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Registration Gateway</title>
    <style>
        :root {
            color-scheme: dark;
            --bg: #0b0f14;
            --panel: #111820;
            --panel-strong: #161f2a;
            --text: #edf2f7;
            --muted: #95a3b3;
            --line: #263241;
            --field: #0d131a;
            --accent: #36c2a4;
            --accent-strong: #20a486;
            --danger-bg: #35171c;
            --danger-text: #ff9aa6;
            --ok-bg: #113328;
            --ok-text: #7de7c4;
        }

        * { box-sizing: border-box; margin: 0; padding: 0; }

        body {
            min-height: 100vh;
            display: grid;
            place-items: center;
            padding: 24px;
            background:
                radial-gradient(circle at top left, rgba(54, 194, 164, .16), transparent 32rem),
                linear-gradient(135deg, #0b0f14 0%, #121821 52%, #090d12 100%);
            color: var(--text);
            font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
        }

        .card {
            width: min(100%, 460px);
            padding: 28px;
            background: linear-gradient(180deg, rgba(22, 31, 42, .96), rgba(13, 19, 26, .98));
            border: 1px solid var(--line);
            border-radius: 8px;
            box-shadow: 0 24px 70px rgba(0, 0, 0, .42);
        }

        .eyebrow {
            margin-bottom: 8px;
            color: var(--accent);
            font-size: .74rem;
            font-weight: 700;
            letter-spacing: .08em;
            text-transform: uppercase;
        }

        h1 {
            margin-bottom: 6px;
            color: var(--text);
            font-size: clamp(1.5rem, 5vw, 2rem);
            line-height: 1.15;
            font-weight: 750;
        }

        .subtitle {
            margin-bottom: 24px;
            color: var(--muted);
            font-size: .95rem;
            line-height: 1.5;
        }

        .grid {
            display: grid;
            gap: 16px;
        }

        label {
            display: block;
            margin-bottom: 7px;
            color: #cbd5df;
            font-size: .83rem;
            font-weight: 650;
        }

        input {
            width: 100%;
            min-height: 44px;
            padding: 11px 12px;
            background: var(--field);
            border: 1px solid var(--line);
            border-radius: 6px;
            color: var(--text);
            font-size: .96rem;
            outline: none;
            transition: border-color .16s ease, box-shadow .16s ease, background .16s ease;
        }

        input:focus {
            background: #101821;
            border-color: var(--accent);
            box-shadow: 0 0 0 3px rgba(54, 194, 164, .15);
        }

        button {
            width: 100%;
            min-height: 46px;
            margin-top: 6px;
            background: var(--accent);
            color: #07120f;
            border: 0;
            border-radius: 6px;
            font-size: 1rem;
            font-weight: 800;
            cursor: pointer;
            transition: transform .16s ease, background .16s ease;
        }

        button:hover { background: var(--accent-strong); }
        button:active { transform: translateY(1px); }

        .meta {
            display: flex;
            justify-content: space-between;
            gap: 12px;
            margin-top: 18px;
            padding-top: 16px;
            border-top: 1px solid var(--line);
            color: var(--muted);
            font-size: .78rem;
        }

        .msg {
            display: none;
            margin-top: 16px;
            padding: 11px 12px;
            border-radius: 6px;
            font-size: .9rem;
            line-height: 1.35;
        }

        .msg.ok { display: block; background: var(--ok-bg); color: var(--ok-text); border: 1px solid rgba(125, 231, 196, .25); }
        .msg.err { display: block; background: var(--danger-bg); color: var(--danger-text); border: 1px solid rgba(255, 154, 166, .25); }

        @media (max-width: 520px) {
            body { padding: 16px; }
            .card { padding: 22px; }
            .meta { flex-direction: column; gap: 6px; }
        }
    </style>
</head>
<body>
<div class="card">
    <div class="eyebrow">HA Registration API</div>
    <h1>Registration Gateway</h1>
    <p class="subtitle">Submit user details through the Laravel service backed by PgBouncer and PostgreSQL streaming replication.</p>

    <form id="regForm" class="grid">
        <div>
            <label for="username">Username</label>
            <input type="text" id="username" name="username" autocomplete="username" required>
        </div>
        <div>
            <label for="email">Email</label>
            <input type="email" id="email" name="email" autocomplete="email" required>
        </div>
        <div>
            <label for="name">Full Name</label>
            <input type="text" id="name" name="name" autocomplete="name">
        </div>
        <div>
            <label for="phone">Phone</label>
            <input type="text" id="phone" name="phone" autocomplete="tel">
        </div>
        <button type="submit">Register</button>
    </form>
    <div id="msg" class="msg"></div>
    <div class="meta">
        <span>Endpoint: /api/register</span>
        <span>Database: PostgreSQL HA</span>
    </div>
</div>
<script>
document.getElementById('regForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    const msg = document.getElementById('msg');
    const data = Object.fromEntries(new FormData(e.target));
    try {
        const res = await fetch('/api/register', {
            method: 'POST',
            headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
            body: JSON.stringify(data)
        });
        if (res.ok) {
            msg.className = 'msg ok';
            msg.textContent = 'Registration successful.';
            e.target.reset();
        } else {
            const err = await res.json();
            msg.className = 'msg err';
            msg.textContent = err.message || 'Validation failed.';
        }
    } catch {
        msg.className = 'msg err';
        msg.textContent = 'Network error.';
    }
});
</script>
</body>
</html>

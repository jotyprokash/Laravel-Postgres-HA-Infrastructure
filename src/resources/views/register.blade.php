<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Register</title>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body { font-family: sans-serif; background: #f4f6f9; display: flex; justify-content: center; align-items: center; min-height: 100vh; }
        .card { background: #fff; padding: 2rem; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.1); width: 100%; max-width: 420px; }
        h1 { margin-bottom: 1.5rem; font-size: 1.4rem; color: #333; }
        label { display: block; margin-bottom: .3rem; font-size: .85rem; color: #555; }
        input { width: 100%; padding: .6rem; margin-bottom: 1rem; border: 1px solid #ddd; border-radius: 4px; font-size: .95rem; }
        button { width: 100%; padding: .7rem; background: #2563eb; color: #fff; border: none; border-radius: 4px; font-size: 1rem; cursor: pointer; }
        button:hover { background: #1d4ed8; }
        .msg { margin-top: 1rem; padding: .6rem; border-radius: 4px; font-size: .9rem; display: none; }
        .msg.ok { display: block; background: #dcfce7; color: #166534; }
        .msg.err { display: block; background: #fee2e2; color: #991b1b; }
    </style>
</head>
<body>
<div class="card">
    <h1>User Registration</h1>
    <form id="regForm">
        <label for="username">Username</label>
        <input type="text" id="username" name="username" required>
        <label for="email">Email</label>
        <input type="email" id="email" name="email" required>
        <label for="name">Full Name</label>
        <input type="text" id="name" name="name">
        <label for="phone">Phone</label>
        <input type="text" id="phone" name="phone">
        <button type="submit">Register</button>
    </form>
    <div id="msg" class="msg"></div>
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

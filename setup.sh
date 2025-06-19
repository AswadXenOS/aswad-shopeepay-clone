#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "[1/6] ✔ Update & Pasang Dependency" pkg update -y && pkg install -y nodejs git sqlite curl

echo "[2/6] ✔ Cipta Struktur Projek" rm -rf shopeepay-clone mkdir -p shopeepay-clone/{backend/{routes,controllers,db},frontend/src/{pages,components},cli} cd shopeepay-clone

echo "[3/6] ✔ Setup Fail Backend" cat > backend/index.js <<'EOF' const express = require('express'); const cors = require('cors'); const app = express(); app.use(cors()); app.use(express.json());

require('./routes/auth.routes')(app); require('./routes/wallet.routes')(app); require('./routes/qr.routes')(app); require('./routes/transaction.routes')(app);

app.listen(3000, () => console.log("Backend ready at http://localhost:3000")); EOF

cat > backend/routes/auth.routes.js <<'EOF' module.exports = (app) => { const controller = require('../controllers/auth.controller'); app.post('/register', controller.register); app.post('/login', controller.login); }; EOF

cat > backend/routes/wallet.routes.js <<'EOF' module.exports = (app) => { const controller = require('../controllers/wallet.controller'); app.post('/topup', controller.topup); app.post('/transfer', controller.transfer); }; EOF

cat > backend/routes/qr.routes.js <<'EOF' module.exports = (app) => { const controller = require('../controllers/qr.controller'); app.post('/pay/qr', controller.payWithQR); }; EOF

cat > backend/routes/transaction.routes.js <<'EOF' module.exports = (app) => { const controller = require('../controllers/transaction.controller'); app.get('/transactions/:user_id', controller.getTransactions); }; EOF

cat > backend/controllers/auth.controller.js <<'EOF' const bcrypt = require('bcryptjs'); const jwt = require('jsonwebtoken'); const db = require('sqlite-sync'); db.connect(__dirname + '/../db/wallet.db');

exports.register = (req, res) => { const { name, phone, password } = req.body; const hash = bcrypt.hashSync(password, 10); try { db.run("INSERT INTO users (name, phone, password) VALUES (?, ?, ?)", [name, phone, hash]); res.json({ status: 'OK' }); } catch (err) { res.status(400).json({ error: err.message }); } };

exports.login = (req, res) => { const { phone, password } = req.body; const user = db.get("SELECT * FROM users WHERE phone = ?", [phone]); if (!user || !bcrypt.compareSync(password, user.password)) { return res.status(401).json({ error: "Login gagal" }); } const token = jwt.sign({ id: user.id }, 'secretkey'); res.json({ token, user: { id: user.id, name: user.name, balance: user.balance } }); }; EOF

cat > backend/controllers/wallet.controller.js <<'EOF' const db = require('sqlite-sync'); db.connect(__dirname + '/../db/wallet.db');

exports.topup = (req, res) => { const { user_id, amount } = req.body; db.run("UPDATE users SET balance = balance + ? WHERE id = ?", [amount, user_id]); db.run("INSERT INTO transactions (user_id, type, amount, target) VALUES (?, 'topup', ?, '-')", [user_id, amount]); res.json({ status: 'OK', message: 'Topup berjaya' }); };

exports.transfer = (req, res) => { const { from_id, to_phone, amount } = req.body; const to = db.get("SELECT id FROM users WHERE phone = ?", [to_phone]); if (!to) return res.status(404).json({ error: 'Penerima tidak dijumpai' }); db.run("UPDATE users SET balance = balance - ? WHERE id = ?", [amount, from_id]); db.run("UPDATE users SET balance = balance + ? WHERE id = ?", [amount, to.id]); db.run("INSERT INTO transactions (user_id, type, amount, target) VALUES (?, 'transfer_out', ?, ?)", [from_id, amount, to_phone]); db.run("INSERT INTO transactions (user_id, type, amount, target) VALUES (?, 'transfer_in', ?, ?)", [to.id, amount, from_id]); res.json({ status: 'OK', message: 'Transfer berjaya' }); }; EOF

cat > backend/controllers/qr.controller.js <<'EOF' const db = require('sqlite-sync'); db.connect(__dirname + '/../db/wallet.db');

exports.payWithQR = (req, res) => { const { from_id, to_phone, amount } = req.body; const to = db.get("SELECT id FROM users WHERE phone = ?", [to_phone]); if (!to) return res.status(404).json({ error: 'QR tidak sah' }); db.run("UPDATE users SET balance = balance - ? WHERE id = ?", [amount, from_id]); db.run("UPDATE users SET balance = balance + ? WHERE id = ?", [amount, to.id]); db.run("INSERT INTO transactions (user_id, type, amount, target) VALUES (?, 'qr_pay', ?, ?)", [from_id, amount, to_phone]); res.json({ status: 'OK', message: 'Bayaran QR berjaya' }); }; EOF

cat > backend/controllers/transaction.controller.js <<'EOF' const db = require('sqlite-sync'); db.connect(__dirname + '/../db/wallet.db');

exports.getTransactions = (req, res) => { const { user_id } = req.params; const list = db.run("SELECT * FROM transactions WHERE user_id = ? ORDER BY created_at DESC", [user_id]); res.json(list); }; EOF

cat > backend/db/schema.sql <<'EOF' CREATE TABLE IF NOT EXISTS users ( id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, phone TEXT UNIQUE NOT NULL, password TEXT NOT NULL, balance REAL DEFAULT 0 ); CREATE TABLE IF NOT EXISTS transactions ( id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER, type TEXT, target TEXT, amount REAL, created_at DATETIME DEFAULT CURRENT_TIMESTAMP ); EOF

echo "[4/6] ✔ Setup Frontend Login" cat > frontend/src/pages/Login.jsx <<'EOF' import { useState } from 'react'; import axios from 'axios';

export default function Login({ setUser }) { const [phone, setPhone] = useState(''); const [password, setPassword] = useState(''); const login = async () => { const res = await axios.post('http://localhost:3000/login', { phone, password }); setUser(res.data.user); }; return ( <div className="p-4"> <h1 className="text-xl font-bold">Login ShopeePay</h1> <input className="border p-2 my-2" placeholder="Phone" value={phone} onChange={e => setPhone(e.target.value)} /> <input className="border p-2 my-2" placeholder="Password" type="password" value={password} onChange={e => setPassword(e.target.value)} /> <button className="bg-orange-500 text-white px-4 py-2" onClick={login}>Login</button> </div> ); } EOF

echo "[5/6] ✔ Setup GPT CLI" cat > cli/gpt-assistant.js <<'EOF' console.log("GPT CLI Assistant aktif"); EOF

echo "[6/6] ✔ Init Projek Node + DB" cd backend npm init -y npm install express cors bcryptjs jsonwebtoken sqlite-sync mkdir -p db && sqlite3 db/wallet.db < db/schema.sql cd ../frontend npm create vite@latest . -- --template react npm install cd ../..

echo "Sistem ShopeePay Clone Siap Penuh Tanpa 2FA" echo "➡ Backend: cd shopeepay-clone/backend && node index.js" echo "➡ Frontend: cd shopeepay-clone/frontend && npm run dev"


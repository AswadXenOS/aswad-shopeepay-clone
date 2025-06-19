const base = 'https://shopeepay-api.onrender.com';

export const login = (phone, password) =>
  fetch(`${base}/login`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ phone, password }) }).then(r => r.json());

export const topup = (id, amount) =>
  fetch(`${base}/topup`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ user_id: id, amount }) }).then(r => r.json());

export const transfer = (from, to, amount) =>
  fetch(`${base}/transfer`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ from_id: from, to_phone: to, amount }) }).then(r => r.json());

export const qrPay = (from, to, amount) =>
  fetch(`${base}/pay/qr`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ from_id: from, to_phone: to, amount }) }).then(r => r.json());

export const getLogs = (id) =>
  fetch(`${base}/transactions/${id}`).then(r => r.json());

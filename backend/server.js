const express = require('express'), cors = require('cors'), app = express();
app.use(cors()); app.use(express.json());
require('./routes/auth.routes')(app);
require('./routes/wallet.routes')(app);
require('./routes/qr.routes')(app);
require('./routes/transaction.routes')(app);
app.get('/', (req, res) => res.send('🛒 ShopeePay API Online'));
app.listen(process.env.PORT || 3000, () => console.log("✅ API running"));

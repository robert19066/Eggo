const express = require('express');
const { exec } = require('child_process');
const cors = require('cors');
const path = require('path');

const app = express();
const PORT = 3001;

app.use(cors());
app.use(express.json());

// Check OS compatibility
app.get('/api/check-os', (req, res) => {
    exec('bash ./oscheck.sh check', (error, stdout, stderr) => {
        if (error) {
            return res.status(500).json({ error: 'Failed to check OS', details: stderr });
        }
        try {
            const result = JSON.parse(stdout);
            res.json(result);
        } catch (e) {
            res.status(500).json({ error: 'Failed to parse OS check result' });
        }
    });
});

// Check root privileges
app.get('/api/check-root', (req, res) => {
    exec('bash ./oscheck.sh root', (error, stdout, stderr) => {
        if (error) {
            return res.status(500).json({ error: 'Failed to check privileges' });
        }
        const isRoot = stdout.trim() === 'true';
        res.json({ isRoot });
    });
});

// Install penguins-eggs (streaming response)
app.post('/api/install', (req, res) => {
    res.setHeader('Content-Type', 'text/event-stream');
    res.setHeader('Cache-Control', 'no-cache');
    res.setHeader('Connection', 'keep-alive');

    const process = exec('bash ./debinstall.sh', { maxBuffer: 1024 * 1024 * 10 });

    process.stdout.on('data', (data) => {
        const lines = data.toString().split('\n').filter(line => line.trim());
        lines.forEach(line => {
            try {
                const json = JSON.parse(line);
                res.write(`data: ${JSON.stringify(json)}\n\n`);
            } catch (e) {
                res.write(`data: ${JSON.stringify({ status: 'info', message: line })}\n\n`);
            }
        });
    });

    process.stderr.on('data', (data) => {
        res.write(`data: ${JSON.stringify({ status: 'error', message: data.toString() })}\n\n`);
    });

    process.on('close', (code) => {
        if (code === 0) {
            res.write(`data: ${JSON.stringify({ status: 'complete', message: 'Installation finished successfully' })}\n\n`);
        } else {
            res.write(`data: ${JSON.stringify({ status: 'error', message: `Installation failed with code ${code}` })}\n\n`);
        }
        res.end();
    });
});

app.listen(PORT, () => {
    console.log(`Backend server running on http://localhost:${PORT}`);
});
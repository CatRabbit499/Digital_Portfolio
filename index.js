import express from 'express';
import path from 'path';

const app = express();
// Serves all files in the 'public' directory
app.use(express.static(path.join(import.meta.dirname, 'templatemo_600_prism_flux')));
app.listen(3000, () => console.log('Server running on port 3000'));

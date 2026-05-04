import express from 'express';
import path from 'path';
import serveIndex from 'serve-index';

const app = express();
// Serves all files in the 'public' directory
app.use(express.static(path.join(import.meta.dirname, 'templatemo_600_prism_flux')));
// Serves the PNG-Unzip project files with directory listing
app.use('/PNG-Unzip',
    express.static('templatemo_600_prism_flux/projects/PNG-Unzip/Files/Files-May_4_2026/'),
    serveIndex('templatemo_600_prism_flux/projects/PNG-Unzip/Files/Files-May_4_2026/', {'icons': true})
);
app.listen(3000, () => console.log('Server running on port 3000'));

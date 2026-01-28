/**
 * 
 * STEP 1 OF BACKSTAGE LEARNING PATH
 *  - Simple Express API
 * 
 * Description: Simulate an API
 * 
 * Reference: 
 *  - Express.js  https://expressjs.com/en/5x/api.html#express.json
 */

// Imports
import express, { Request, Response } from "express";

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware for parsing application/json
app.use(express.json());

// Health check endpoint
app.get("/health", (req: Request, res: Response) => {
  res.json({
    status: "healthy",
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
  });
});

// Main endpoint
app.get("/", (req: Request, res: Response) => {
  res.json({
    message: "Hello Platform Engineering!",
    version: "1.0.0",
    environment: process.env.NODE_ENV || "development",
  });
});

// Info endpoint
app.get("/info", (req: Request, res: Response) => {
  res.json({
    app: "hello-platform",
    description: "A simple app to practice Platform Engineering",
    technologies: [
      "TypeScript",
      "Express",
      "Docker",
      "Kubernetes",
      "Helm",
      "ArgoCD",
      "Backstage",
    ],
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
  console.log(`Health check: http://localhost:${PORT}/health`);
  console.log(`Info: http://localhost:${PORT}/info`);
});

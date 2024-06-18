# Use the official Node.js 18 image as a base
FROM node:20

# Set the working directory in the Docker container
WORKDIR /app

# Copy package.json and package-lock.json (or yarn.lock) to the container
COPY package*.json ./

# Install production dependencies.
RUN npm install --only=production

# Copy the rest of your application code to the container
COPY . .

# Expose the port your app runs on
EXPOSE 3000

# Set environment variables
ENV NODE_ENV=production
# Ensure you have the correct environment variables for your database and other services
# ENV DATABASE_URL=your-database-url

# Command to run your application
CMD ["npm", "start"]
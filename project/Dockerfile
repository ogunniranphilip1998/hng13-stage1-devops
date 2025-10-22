# Use the official Nginx image as a base
FROM nginx:latest

# Copy your HTML file (if it’s named index.html) into the Nginx default directory
COPY index.html /usr/share/nginx/html/

# Expose port 80 for web traffic
EXPOSE 80

# Start Nginx when the container runs
CMD ["nginx", "-g", "daemon off;"]

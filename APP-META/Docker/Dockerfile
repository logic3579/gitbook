FROM busybox

# Set an environment variable
ENV APP /knowledge

# Create the directory
RUN mkdir $APP
WORKDIR $APP

# We copy the rest of the codebase into the image
COPY . .

#ENTRYPOINT ["/bin/entrypoint.sh"]
CMD ["echo", "knowledge"]

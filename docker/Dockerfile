FROM ubuntu:14.04
MAINTAINER Yu-Chen Chang <edcyc.tw@gmail.com>

# Install curl
RUN apt-get install -y curl

# For python script
# Install python
RUN apt-get -y install python
# Download pip
RUN apt-get -y install python-pip
# Install python httplib2
RUN pip install httplib2
# Install python yaml
RUN pip install pyyaml
# Install mkdocs
pip install mkdocs

# Bundle app source
COPY . /src

# Expose port
EXPOSE 8000

# Run
RUN chmod a+x /src/run.sh
CMD ["/src/run.sh"]

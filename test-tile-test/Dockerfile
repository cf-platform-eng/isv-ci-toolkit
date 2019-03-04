FROM cfplatformeng/toolkit-pas

# Assumptions
# * Volume mount containing our tile
# * JSON file from Toolsmiths (json file from toolsmiths)

COPY artifacts/tileinspect /usr/local/bin

CMD [ \
    "/bin/bash", \
    "-c", \
    " \
    om staged-products && \
    tileinspect metadata -f json -t /tile/*.pivotal | jq "." && \
    bash \
    " \
    ]

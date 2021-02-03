FROM harbor-repo.vmware.com/partner_engineering/marman:0.4.5          AS marman
FROM harbor-repo.vmware.com/partner_engineering/om:7.1.2              AS om
FROM harbor-repo.vmware.com/partner_engineering/isv-ci-toolkit:0.0.25 AS tools

FROM harbor-repo.vmware.com/partner_engineering/base-image:0.0.47

# Copy binaries from dependent images
COPY --from=marman /usr/local/bin/marman /usr/local/bin/
COPY --from=om /usr/local/bin/om /usr/local/bin/
COPY --from=tools /usr/local/bin/*.sh /usr/local/bin/

RUN apt-get update && apt-get install -y gettext-base node-semver && rm -rf /var/lib/apt/lists/*

# Copy files for this test
COPY ["needs.json", "run.sh", "${JOB_DIR}/"]
RUN chmod a+x ${JOB_DIR}/*.sh

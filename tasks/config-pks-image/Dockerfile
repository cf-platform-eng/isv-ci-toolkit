FROM harbor-repo.vmware.com/partner_engineering/marman:0.4.5       AS marman
FROM harbor-repo.vmware.com/partner_engineering/om:7.1.2           AS om
FROM harbor-repo.vmware.com/partner_engineering/tileinspect:0.5.11 AS tileinspect

FROM harbor-repo.vmware.com/partner_engineering/base-image:0.0.47

RUN apt-get update && apt-get install -y gettext-base gnupg node-semver && rm -rf /var/lib/apt/lists/*

COPY --from=marman      /usr/local/bin/marman      /usr/local/bin/
COPY --from=om          /usr/local/bin/om          /usr/local/bin/
COPY --from=tileinspect /usr/local/bin/tileinspect /usr/local/bin/

COPY ./*.sh {JOB_DIR}/
RUN chmod a+x ${JOB_DIR}/*.sh

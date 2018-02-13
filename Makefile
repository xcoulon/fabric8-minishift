.PHONY: help
# Based on https://gist.github.com/rcmachado/af3db315e31383502660
## Display this help text.
help:/
	$(info Available targets)
	$(info -----------------)
	@awk '/^[a-zA-Z\-\_0-9]+:/ { \
		helpMessage = match(lastLine, /^## (.*)/); \
		helpCommand = substr($$1, 0, index($$1, ":")-1); \
		if (helpMessage) { \
			helpMessage = substr(lastLine, RSTART + 3, RLENGTH); \
			gsub(/##/, "\n                                     ", helpMessage); \
		} else { \
			helpMessage = "(No documentation)"; \
		} \
		printf "%-35s - %s\n", helpCommand, helpMessage; \
		lastLine = "" \
	} \
	{ hasComment = match(lastLine, /^## (.*)/); \
          if(hasComment) { \
            lastLine=lastLine$$0; \
	  } \
          else { \
	    lastLine = $$0 \
          } \
        }' $(MAKEFILE_LIST)

KEDGE_BIN_NAME := kedge
KEDGE_BIN := $(shell command -v $(KEDGE_BIN_NAME) 2> /dev/null)
OC_USERNAME := developer
OC_PASSWORD := developer
OC_SA_USERNAME := devtools-sa
OC_SA_PASSWORD := devtools-sa
MINISHIFT_IP := $(shell minishift ip)

.PHONY: init
init: tmp ./tmp/init.touch

./tmp/init.touch:
	@echo "Initializing accounts"
	@oc adm policy  --as system:admin add-cluster-role-to-user cluster-admin developer #make sure that `developer` account is cluster admin

	@oc apply -f developer-user.yml
	@oc adm policy  --as system:admin add-cluster-role-to-user cluster-admin devtools-sa
	
	@oc apply -f devtools-sa-user.yml
	@touch ./tmp/init.touch

.PHONY: clean
clean:
	@rm -rf ./tmp
	@mkdir ./tmp

tmp:
	@mkdir ./tmp

.PHONY: login-dev
login-dev: init
	echo "logging on $(MINISHIFT_IP) with $(OC_USERNAME) account..."
	@oc login --insecure-skip-tls-verify=true https://$(MINISHIFT_IP):8443 -u $(OC_USERNAME) -p $(OC_PASSWORD) 1>/dev/null
	@oc whoami -t > tmp/developer.txt

.PHONY: login-sa
login-sa: init
	echo "logging on $(MINISHIFT_IP) with $(OC_SA_USERNAME) account..."
	@oc login https://$(MINISHIFT_IP):8443 -u $(OC_SA_USERNAME) -p $(OC_SA_PASSWORD) 1>/dev/null
	@oc whoami -t > tmp/serviceaccount.txt

.PHONY: login
login: login-dev

.PHONY: deploy-kc
deploy-kc: $(KEDGE_BIN) login
	@kedge apply -f keycloak-cm.yml
	@kedge apply -f keycloak-db.yml
	@kedge apply -f keycloak.yml
	
.PHONY: deploy-auth
deploy-auth: $(KEDGE_BIN) login
	@kedge apply -f auth-db.yml
	@MINISHIFT_IP=$(MINISHIFT_IP) kedge apply -f auth.yml

.PHONY: deploy-toggles
deploy-toggles: $(KEDGE_BIN) login
	@kedge apply -f toggles-db.yml
	@kedge apply -f toggles.yml

.PHONY: deploy-toggles-service
deploy-toggles-service: $(KEDGE_BIN) login
	@kedge apply -f toggles-service.yml

.PHONY: deploy-tenant
deploy-tenant: $(KEDGE_BIN) login
	@echo using $(SA_TOKEN) service token to deploy tenant service
	@kedge apply -f tenant-db.yml
	@MINISHIFT_IP=$(MINISHIFT_IP) SERVICE_TOKEN=`cat tmp/serviceaccount.txt` kedge apply -f tenant.yml

.PHONY: deploy-wit
deploy-wit: $(KEDGE_BIN) login
	@kedge apply -f wit-db.yml
	@MINISHIFT_IP=$(MINISHIFT_IP) kedge apply -f wit.yml


.PHONY: deploy-ui
deploy-ui: $(KEDGE_BIN) login
	@MINISHIFT_IP=$(MINISHIFT_IP) kedge apply -f ui.yml



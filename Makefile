define makeRandom
$(shell mktemp -u | sed -E 's/(\.|\/tmp)//g')
endef



LAYER_DIR:=layer

CODE_ZIP:=src.zip
LAYER_ZIP:=layer.zip


help:
	@python -c 'import fileinput,re; \
	ms=filter(None, (re.search("([a-zA-Z_-]+):.*?## (.*)$$",l) for l in fileinput.input())); \
	print("\n".join(sorted("\033[36m  {:25}\033[0m {}".format(*m.groups()) for m in ms)))' $(MAKEFILE_LIST)

check:		## Print versions of required tools
	docker --version
	docker-compose --version
	python3 --version
	python --version
	pip --version
	aws --version
	pipreqs --version || pip install -q pipreqs

clean:		## Clean
	@rm -rf $(LAYER_DIR)
	@rm -rf __pycache__
	@rm -f requirements.txt
	@rm -rf src
	@rm -f .env
	@rm -f $(LAYER_ZIP)
	@rm -rf $(CODE_ZIP)

fetch-bin: _dotenv
	$(eval CHORMEDRIVER_URL:=https://chromedriver.storage.googleapis.com/${CHORMEDRIVER_VERSION}/chromedriver_linux64.zip)
	$(eval CHROME_URL:=https://github.com/adieuadieu/serverless-chrome/releases/download/${CHROME_VERSION}/stable-headless-chromium-amazonlinux-2017-03.zip)
	@mkdir -p bin/

	curl -sSL $(CHORMEDRIVER_URL) > chromedriver.zip
	@unzip -o chromedriver.zip -d bin/

	curl -sSL $(CHROME_URL) > headless-chromium.zip
	@unzip -o headless-chromium.zip -d bin/

	@rm headless-chromium.zip chromedriver.zip

run: build-docker ## Run project in lambda docker
	docker-compose run lambda lambda_function.lambda_handler

build-docker: build-layer
	docker-compose build

build-layer: generate-requirements fetch-bin
	mkdir $(LAYER_DIR)
	cp -r bin $(LAYER_DIR)/
	cp -r lib $(LAYER_DIR)/
	pip install -q -q -r requirements.txt -t $(LAYER_DIR)/python

publish-layer: build-layer ## Publish aws lambda layer
	cd $(LAYER_DIR); zip -9qr ../$(LAYER_ZIP) .
	cd ..
	$(eval NAME := $(call makeRandom))
	$(eval REMOTE := "s3://${AWS_S3_BUCKET}/$(NAME).zip")
	@aws s3 cp $(LAYER_ZIP) $(REMOTE)
	aws lambda publish-layer-version --layer-name ${AWS_LAMBDA_LAYER_NAME} \
		--description ${AWS_LAMBDA_LAYER_DESCRIPTION} \
		--compatible-runtimes python3.7 \
		--content S3Bucket=${AWS_S3_BUCKET},S3Key=$(NAME).zip
	@aws s3 rm $(REMOTE)


copy-outer: clean 
	@mkdir src
	@cp -r ../src/* src/
	@cp ../.env .env

generate-requirements: copy-outer
	@pipreqs src --savepath requirements.txt

publish-code: _dotenv generate-requirements ## publish aws lambda function code
	cd src; zip -9qr ../$(CODE_ZIP) .
	cd ..
	$(eval NAME := $(call makeRandom))
	$(eval REMOTE := "s3://${AWS_S3_BUCKET}/$(NAME).zip")
	@aws s3 cp $(CODE_ZIP) $(REMOTE)
	aws lambda update-function-code --function-name ${AWS_LAMBDA_FUNCTION_NAME}\
		--s3-bucket ${AWS_S3_BUCKET} --s3-key $(NAME).zip --publish
	@aws s3 rm $(REMOTE)

_generate-env-sample:
	@head -n 5 ../.env > .env.sample
	@tail -n +6 ../.env | sed -E "s/\=.*/=/" >> .env.sample

_dotenv: copy-outer
	$(eval include .env)
	$(eval export)

.PHONY: help check clean fetch-bin run build-docker build-layer publish-layer copy-outer \
	generate-requirements publish-code _generate-env-sample _dotenv

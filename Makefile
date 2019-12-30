deploy-vk-debug:
	git push gigalixir vk-debug:master
deploy-production:
	git push gigalixir master
logs:
	gigalixir logs
ps:
	gigalixir ps
bills:
	gigalixir account:usage
migrate-prod:
	gigalixir ps:migrate

TITLE="Pomonella"
NAME=pomonella
ARCHIVE=${NAME}.zip
GAME_URL=https://${HOSTNAME}/${NAME}
SERVER_PATH=/var/www/play.c7.se/${NAME}
HOSTNAME=play.c7.se
BACKUP_PATH=/run/user/1000/gvfs/smb-share:server=diskstation.local,share=backups/Code/Fantasy/WASM-4

all:
	zig build

.PHONY: spy
spy:
	zig build spy

.PHONY: run
run:
	zig build run

.PHONY: clean
clean:
	rm -rf build
	rm -rf bundle

.PHONY: bundle
bundle: all
	@w4 bundle zig-out/bin/cart.wasm --title ${TITLE} --html bundle/${NAME}.html 		# HTML
	@w4 bundle zig-out/bin/cart.wasm --title ${TITLE} --linux bundle/${NAME}.elf 		# Linux (ELF)
	@w4 bundle zig-out/bin/cart.wasm --title ${TITLE} --windows bundle/${NAME}.exe 	# Windows (PE32+)
	@cp zig-out/bin/cart.wasm bundle/${NAME}.wasm
	@zip -juq bundle/${ARCHIVE} bundle/${NAME}.html bundle/${NAME}.elf bundle/${NAME}.exe bundle/${NAME}.wasm
	@echo "✔ Updated bundle/${ARCHIVE}"

.PHONY: backup
backup: bundle
	@mkdir -p ${BACKUP_PATH}/${NAME}
	@cp bundle/${NAME}.* ${BACKUP_PATH}/${NAME}/
	@echo "✔ Backed up to ${BACKUP_PATH}/${NAME}"

.PHONY: deploy
deploy: bundle
	@ssh ${HOSTNAME} 'mkdir -p ${SERVER_PATH}'
	@scp -q bundle/${NAME}.html ${HOSTNAME}:${SERVER_PATH}/index.html
	@scp -q bundle/${NAME}.wasm ${HOSTNAME}:${SERVER_PATH}/${NAME}.wasm
	@scp -q -r src ${HOSTNAME}:${SERVER_PATH}/
	@scp -q build.zig* ${HOSTNAME}:${SERVER_PATH}/
	@echo "✔ Updated ${NAME} on ${GAME_URL}"
	@scp -q bundle/${ARCHIVE} ${HOSTNAME}:${SERVER_PATH}/${ARCHIVE}
	@echo "✔ Archive ${GAME_URL}/${ARCHIVE}"

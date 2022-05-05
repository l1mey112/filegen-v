import os
import x.json2 as json
import encoding.hex
import rand
import term

fn get_magic(mimetypes json.Any, search string)([]string, string){
	mime := mimetypes.as_map()[search] or {
		println("failed to find extension!")
		exit(1)
	}.as_map()
	signs := mime["signs"] or {
		println(term.red("FATAL: failed to find signs, check json?"))
		exit(1)
	}.arr()
	mut reconstruct := []string{}
	for s in signs{
		reconstruct << s.str()
	}
	mimetype := mime["mime"] or {
		println(term.red("FATAL: failed to find mimetype, check json?"))
		exit(1)
	}.str()
	return reconstruct, mimetype
}

fn parse_magic(sign string)(int,[]u8){
	slice := sign.split(",")
	return slice[0].int(),hex.decode(slice[1]) or {
		println(term.red("FATAL: failed to decode data string, check json?"))
		exit(1)
	}
}

fn main(){
	mimetypes := json.raw_decode($embed_file('mime.json', .zlib).to_string()) or {
		println(term.red("FATAL: mime.json failed parsing, check json?"))
		exit(1)
	}

	if os.args.len == 3 && os.args[1] == "help" && os.args[2] == "list"{
		for extension, mime in mimetypes.as_map() {
			mtype := mime.as_map()['mime'] or {
				println(term.red("FATAL: failed to find mimetype, check json?"))
				exit(1)
			}.str()
			mut out := "${extension}		${mtype}"
			out = if mtype.contains("application") {
				(out)
			} else if mtype.contains("audio") {
				term.yellow(out)
			} else if mtype.contains("video") {
				term.blue(out)
			} else if mtype.contains("image") {
				term.green(out)
			} else if mtype.contains("text") {
				term.gray(out)
			} else if mtype.contains("message") {
				term.magenta(out)
			} else {out}
			println(out)
		}
		exit(0)
	}
	
	if os.args.len == 2 && os.args[1] == "help"{
		println(
"This is an application to create garbage files with magic signatures for any purpose.
It can be used to fake a large number of formats, to list them all use:
  $ ${term.green(os.base(os.args[0])+" help list")}

Default usage: 
  $ ${term.green("Usage: "+os.base(os.args[0])+" <extension> <MBs size> <output file>")}

${term.magenta("l-m.dev - 2022")}
${term.gray("Thanks to qti3e on github for the mimetype json data!")}"
		)
		exit(0)
	}

	if os.args.len != 4 {
		println("Usage: ${os.base(os.args[0])} <extension> <MBs size> <output file>")
		println(term.magenta("Type help for more information!"))
		exit(1)
	}

	search := "pdf"

	mbs := 8

	length := mbs * 1024 * 1024

	mut file := []u8{cap: length, len: length}
	for i in 0..length {file[i] = rand.u8()}

	signs, _ := get_magic(mimetypes, search)
	// mimestr
	//println(mimestr+"\n")

	mut pointer := 0
	for sign in signs{
		offset, data := parse_magic(sign)
		pointer += offset
		for i in 0..data.len{
			file[pointer] = data[i]
			pointer++
		}
	}

	os.write_file_array(os.join_path_single(os.getwd(), os.args[3]),file) or {
		println("failed to write file")
		exit(1)
	}
}
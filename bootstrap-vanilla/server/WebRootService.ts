import {Global} from "./global"
import {index} from "./index"

export class WebRootService {
    constructor() {
    }

    requestHandler(url: any, req: any, res: any){
        let parsed  = Global.nodeUrl.parse(url)
        let fileName = parsed.pathname == "/" ? "/index.html" : parsed.pathname
        let fileExt = ((fileName.match(/\.[a-zA-Z0-9]+$|\?/) || [''])[0]).toLowerCase()
        let fileMime: any = fileExt in index.mimetable ? index.mimetable[fileExt] : "application/octet-stream"

        if(fileName.indexOf("//").toString() !=-1) console.log(fileName.toString(), "Invalid URL")
        let httpRoot = `${process.cwd()}`
        httpRoot = httpRoot.substr(0, httpRoot.lastIndexOf("/"));
        httpRoot += "/webRoot"
        console.log(httpRoot)

        if(fileName == "/index.html"){ console.log(`${Date()}\n`) }
        //console.log(`Sending: ${fileName}`)

        /** lookup filename */
        let fileFull = httpRoot + fileName

        if(fileExt == ""){
            fileFull = httpRoot + fileName + ".js"
        }


        Global.nodeFs.stat(fileFull, (err: any, stat: any) => {
            if(err !=null){
                res.writeHead(404, JSON.parse(`{ "Content-Type": "text/html"} `))
                res.end("File not found")
                return
            }

            /** Check the etag */
            let etag = `${stat.mtime.getTime()}_${stat.size}`
            if(req.headers["if-none-match"] === etag){
                res.writeHead(304)
                res.end()
                return
            }

            /** send the file */
            if (req.headers["accept-encoding"].toString().indexOf("gzip") == -1) {
                let stream = Global.nodeFs.createReadStream(fileFull)
                res.writeHead(200, {
                    "Connection": "Close",
                    "Cache-control": "max-age=0",
                    "Content-Type": `${fileMime}`,
                    "Content-Length": `${stat.size}`,
                    "etag": `${etag}`,
                    "mtime": `${stat.mtime.getTime()}`
                })
                stream.pipe(res)
            }

            if (fileExt == ".glsl") {
                let stream = Global.nodeFs.createReadStream(fileFull)
                res.writeHead(200, {
                    "Sec-WebSocket-Protocol": "binary",
                    "Connection": "Close",
                    "Cache-control": "max-age=0",
                    "Content-Type": `${fileMime}`,
                    "Content-Length": `${stat.size}`,
                    "etag": `${etag}`,
                    "mtime": `${stat.mtime.getTime()}`
                })
                stream.pipe(res)
            }

            else {
                let stream = Global.nodeFs.createReadStream(fileFull)
                res.writeHead(200,{
                    "Connection": "Close",
                    "Cache-control": "max-age=0",
                    "Content-Type": `${fileMime}`,
                    "Content-Length": `${stat.size}`,
                    "Content-Encoding":"gzip",
                    "etag": `${etag}`,
                    "mtime": `${stat.mtime.getTime()}`
                })
                stream.pipe(Global.nodezlib.createGzip()).pipe(res)
            }
        })
    }
}
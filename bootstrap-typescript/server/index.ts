import {Global} from "./global"
import {WebRootService} from "./WebRootService";

export type key = string
export type mutmap<K extends key, V> = { [key in K]: V }

export class index {
    serverPort = 8888
    serverInterface = '0.0.0.0'
    webRootService = new WebRootService()

    static mimetable: mutmap<string, string> = {
        ".map": "application/json",
        ".html": "text/html",
        ".js": "application/javascript",
        ".ico": "image/x-icon",
        ".glsl": "text/plain",
        ".wasm": "application/wasm"
    }

    constructor() {
        this.webServer()
    }

    webServer(): void {
        let app = Global.nodeHttp.createServer((req: any, res: any)=> {
            let url = req.url
            this.webRootService.requestHandler(url, req, res)
        }).listen(this.serverPort, this.serverInterface, (err: any)=>{
            if(err == true){
                return console.log("Server error ", err.message)
            }

            console.log(`Server is listening on http://localhost:${this.serverPort}/`)

            /** Dump Listeners */
            //let interfaces = Global.nodeOs.networkInterfaces()
            //let keys = Object.keys(interfaces)
            //keys.forEach((key: any)=>{
            //    console.log(`Server is listening on http://${interfaces[key][0]["address"]}:${this.serverPort}/`)
            //})
        })
    }
}

new index()
import { LightningElement } from "lwc";
import DFD_Footer_Resources from "@salesforce/resourceUrl/DFD_Footer_Resource";
export default class DfdFooterComponent extends LightningElement {
  facebook = DFD_Footer_Resources + "/facebook-white-48px.png";
  youtube = DFD_Footer_Resources + "/youtube-white-48px.png";
  twitter = DFD_Footer_Resources + "/twitter-white-48px.png";
  rss = DFD_Footer_Resources + "/rss-white-48px.png";
  nextdoor = DFD_Footer_Resources + "/nextdoor-white-48px.png";
  stl_seal = DFD_Footer_Resources + "/white-city-seal.png.png";
}
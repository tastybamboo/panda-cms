import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  changePeriod(event) {
    const period = event.target.value
    const url = new URL(window.location)
    url.searchParams.set("period", period)
    window.location = url.toString()
  }
}

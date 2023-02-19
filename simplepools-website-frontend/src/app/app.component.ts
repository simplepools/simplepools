import { Component, OnInit } from '@angular/core';
import { ChildrenOutletContexts, Router } from '@angular/router';
import { slideInAnimation } from './animations';

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.css'],
  animations: [
    slideInAnimation,
  ]
})
export class AppComponent implements OnInit {

  title = 'Simple Pools';

  routerLinks = [
    ['/homepage', "Homepage"],
    ['/pools', "Pools"],
  ]

  activatedRoute = this.routerLinks[0][0];

  constructor(
    private router: Router,
    private contexts: ChildrenOutletContexts,
  ) {}

  ngOnInit() {
  }

  navigate(route: string) {
    this.activatedRoute = route;
    this.router.navigate([route]);
  }

  getRouteAnimationData() {
    return this.contexts.getContext('primary')?.route?.snapshot?.data?.['animation'];
  }

}

export let webworker: Worker;
if (typeof Worker !== 'undefined') {
  // Create a new
  const worker = new Worker(new URL('./app.worker', import.meta.url));
  // (worker as any)['global'] = window;
  // worker.onmessage = ({ data }) => {
    // console.log(`page got message: ${data}`);
  // };
  // worker.postMessage('hello');
  webworker = worker;
} else {
  console.error('web workers are not supported');
  // Web Workers are not supported in this environment.
  // You should add a fallback so that your program still executes correctly.
}


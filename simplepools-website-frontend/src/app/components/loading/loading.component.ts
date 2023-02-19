import { Component, OnInit } from '@angular/core';
import { LoadingService } from '../../services/loading/loading.service';

@Component({
  selector: 'loading',
  templateUrl: './loading.component.html',
  styleUrls: ['./loading.component.css']
})
export class LoadingComponent implements OnInit {

  showLoadingSpinner = false;
  loadingText = "";//"Getting data from the blockchain"
  numberOfDots = 20;
  initialDots = "...";
  dots = this.initialDots;
  intervalId: any;
  

  startChangingDots() {
    this.intervalId = setInterval(() => {
      if (this.dots.length > this.numberOfDots) {
        this.dots = this.initialDots;
      } else {
        this.dots += '.';
      }
    }, 300);
  }

  stopChangingDots() {
    clearInterval(this.intervalId);
  }

  constructor(private loaderService: LoadingService) {

    this.loaderService.isLoading.subscribe((value) => {
      this.showLoadingSpinner = value;
      if (value === true) {
        this.startChangingDots();
      } else {
        this.stopChangingDots();
      }
    });

  }
  ngOnInit() {
  }

}
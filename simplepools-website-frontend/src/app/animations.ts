import { animate, animateChild, group, query, style, transition, trigger } from "@angular/animations";

export const slideInAnimation =
  trigger('routeAnimations', [
    transition('homepage => pools', [
      style({
         position: 'relative',
      }),
      query(':enter, :leave', [
        style({
          position: 'absolute',
          bottom: 0,
          height: '100%',
          width: '100%'
        })
      ],),
      query(':enter',  style({ 
        position: 'absolute',
        opacity: 0,
        // right: '-100%',
        // bottom: '-1000px',
      })),
      query(':leave', animateChild()),
      group([
        query('.slogan', [
          style({
            display: 'none',
         }),
        ]),
        query('.footer', [
          style({
            display: 'none',
         }),
        ]),
        query('.show-buttons', [
          style({
            display: 'none',
         }),
        ]),
        query(':leave', [
          animate('300ms ease-out', 
          style({
            height: '10%',
            width: '10%',
         }))
        ],),
        query(':enter', [
          animate('300ms ease-out', style({
             opacity: 1,
            }))
        ]),
      ]),
    ]),
    transition('pools => pool-details', [
      style({
        position: 'relative',
     }),
     query(':enter, :leave', [
       style({
         position: 'absolute',
         bottom: 0,
         height: '100%',
         width: '100%'
       })
     ],),
     query(':enter',  style({
      opacity: 0.1,
     })),
     group([
       query(':leave', [
         animate('100ms ease-out', 
         style({
          opacity: '0.5',
         }))
       ],),
       query(':enter', [
         animate('100ms ease-out', style({
            opacity: 0.9,
           }))
       ]),
     ]),
    ]),
  ]);
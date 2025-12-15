import { Component, Input } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FragmentationResult } from '../../models/fragmentation.model';

@Component({
  selector: 'app-fragmentation-results',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './fragmentation-results.component.html',
  styleUrl: './fragmentation-results.component.scss'
})
export class FragmentationResultsComponent {
  @Input() result: FragmentationResult | null = null;

  getPhasePercentage(phaseTime: number | null): number {
    if (!phaseTime || !this.result?.executionTimeSeconds) return 0;
    return (phaseTime / this.result.executionTimeSeconds) * 100;
  }

  formatNumber(num: number): string {
    return num.toLocaleString('en-US');
  }

  formatTime(seconds: number): string {
    if (seconds < 1) {
      return `${(seconds * 1000).toFixed(2)} ms`;
    }
    return `${seconds.toFixed(3)} s`;
  }
}

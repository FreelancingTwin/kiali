import * as React from 'react';
import { DEGRADED, FAILURE, HEALTHY, NOT_READY } from '../../types/Health';
import { OverviewStatus } from './OverviewStatus';
import { OverviewType } from './OverviewToolbar';
import { NamespaceStatus } from '../../types/NamespaceInfo';
import { switchType } from './OverviewHelper';
import { Paths } from '../../config';

type Props = {
  name: string;
  status: NamespaceStatus;
  type: OverviewType;
};

export const NamespaceStatuses: React.FC<Props> = (props: Props) => {
  const targetPage = switchType(props.type, Paths.APPLICATIONS, Paths.SERVICES, Paths.WORKLOADS);
  const name = props.name;
  const status = props.status;

  const nbItems =
    status.inError.length +
    status.inWarning.length +
    status.inSuccess.length +
    status.notAvailable.length +
    status.inNotReady.length;

  let text: string;

  if (nbItems === 1) {
    text = switchType(props.type, '1 application', '1 service', '1 workload');
  } else {
    text = `${nbItems}${switchType(props.type, ' applications', ' services', ' workloads')}`;
  }

  return (
    <>
      <div style={{ textAlign: 'left' }}>
        <span>
          <div style={{ display: 'inline-block', width: '125px' }} data-test={`overview-type-${props.type}`}>
            {text}
          </div>

          <div style={{ display: 'inline-block' }}>
            {status.inNotReady.length > 0 && (
              <OverviewStatus
                id={`${name}-not-ready`}
                namespace={name}
                status={NOT_READY}
                items={status.inNotReady}
                targetPage={targetPage}
              />
            )}

            {status.inError.length > 0 && (
              <OverviewStatus
                id={`${name}-failure`}
                namespace={name}
                status={FAILURE}
                items={status.inError}
                targetPage={targetPage}
              />
            )}

            {status.inWarning.length > 0 && (
              <OverviewStatus
                id={`${name}-degraded`}
                namespace={name}
                status={DEGRADED}
                items={status.inWarning}
                targetPage={targetPage}
              />
            )}

            {status.inSuccess.length > 0 && (
              <OverviewStatus
                id={`${name}-healthy`}
                namespace={name}
                status={HEALTHY}
                items={status.inSuccess}
                targetPage={targetPage}
              />
            )}

            {nbItems === status.notAvailable.length && (
              <div style={{ display: 'inline-block', marginLeft: '0.5rem' }}>N/A</div>
            )}
          </div>
        </span>
      </div>
    </>
  );
};

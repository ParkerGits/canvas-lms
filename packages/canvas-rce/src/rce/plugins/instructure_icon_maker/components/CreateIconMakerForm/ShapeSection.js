/*
 * Copyright (C) 2021 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import React, {useEffect} from 'react'

import {Flex} from '@instructure/ui-flex'
import {SimpleSelect} from '@instructure/ui-simple-select'

import formatMessage from '../../../../../format-message'
import {Shape} from '../../svg/shape'
import {Size} from '../../svg/constants'

import {createCroppedImageSvg} from './ImageCropper/imageCropUtils'
import {convertFileToBase64} from '../../svg/utils'

import {actions} from '../../reducers/svgSettings'

const SIZES = [Size.ExtraSmall, Size.Small, Size.Medium, Size.Large]

export const ShapeSection = ({settings, onChange}) => {
  useEffect(() => {
    // if the user has an embedded image, we need to re-crop it so it fits the new shape
    if (settings.imageSettings?.cropperSettings) {
      const newCropperSettings = {...settings.imageSettings.cropperSettings, shape: settings.shape}
      createCroppedImageSvg(newCropperSettings, settings.imageSettings.image)
        .then(generatedSvg =>
          convertFileToBase64(new Blob([generatedSvg.outerHTML], {type: 'image/svg+xml'}))
        )
        .then(base64Image => {
          onChange({
            type: actions.SET_EMBED_IMAGE,
            payload: base64Image,
          })
          onChange({
            type: actions.SET_IMAGE_SETTINGS,
            payload: {...settings.imageSettings, cropperSettings: newCropperSettings},
          })
        })
        // eslint-disable-next-line no-console
        .catch(error => console.error(error))
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [settings.shape])

  return (
    <Flex as="section" direction="column" justifyItems="space-between" padding="small small 0">
      <Flex.Item padding="small">
        <SimpleSelect
          assistiveText={formatMessage('Use arrow keys to select a shape.')}
          id="icon-shape"
          onChange={(e, option) => onChange({shape: option.value})}
          renderLabel={formatMessage('Icon Shape')}
          value={settings.shape}
        >
          {Object.values(Shape).map(shape => (
            <SimpleSelect.Option id={`shape-${shape}`} key={`shape-${shape}`} value={shape}>
              {SHAPE_DESCRIPTION[shape] || ''}
            </SimpleSelect.Option>
          ))}
        </SimpleSelect>
      </Flex.Item>

      <Flex.Item padding="small">
        <SimpleSelect
          assistiveText={formatMessage('Use arrow keys to select a size.')}
          id="icon-size"
          onChange={(e, option) => onChange({size: option.value})}
          renderLabel={formatMessage('Icon Size')}
          value={settings.size}
        >
          {SIZES.map(size => (
            <SimpleSelect.Option id={`size-${size}`} key={`size-${size}`} value={size}>
              {SIZE_DESCRIPTION[size] || ''}
            </SimpleSelect.Option>
          ))}
        </SimpleSelect>
      </Flex.Item>
    </Flex>
  )
}

const SHAPE_DESCRIPTION = {
  [Shape.Square]: formatMessage('Square'),
  [Shape.Circle]: formatMessage('Circle'),
  [Shape.Triangle]: formatMessage('Triangle'),
  [Shape.Diamond]: formatMessage('Diamond'),
  [Shape.Pentagon]: formatMessage('Pentagon'),
  [Shape.Hexagon]: formatMessage('Hexagon'),
  [Shape.Octagon]: formatMessage('Octagon'),
  [Shape.Star]: formatMessage('Star'),
}

const SIZE_DESCRIPTION = {
  [Size.ExtraSmall]: formatMessage('Extra Small'),
  [Size.Small]: formatMessage('Small'),
  [Size.Medium]: formatMessage('Medium'),
  [Size.Large]: formatMessage('Large'),
}

import { ReactElement, MouseEvent } from 'react';
import { Stage, Layer, Rect, Image, Line } from 'react-konva';
import useImage from 'use-image';

import { Controller, useGameContext } from "./GameProvider";




// Well we should probably use proper numbers, but for now we lerp on hex strings...
const lerpColor = (a: string, b: string, amount: number) => {
    let ah = parseInt(a.replace(/#/g, ''), 16),
        ar = ah >> 16, ag = ah >> 8 & 0xff, ab = ah & 0xff,
        bh = parseInt(b.replace(/#/g, ''), 16),
        br = bh >> 16, bg = bh >> 8 & 0xff, bb = bh & 0xff,
        rr = ar + amount * (br - ar),
        rg = ag + amount * (bg - ag),
        rb = ab + amount * (bb - ab);
    return '#' + ((1 << 24) + (rr << 16) + (rg << 8) + rb | 0).toString(16).slice(1);
}


type GameCanvasProps = {
    height: number;
    width: number;
};

const GameCanvas = ({
    height,
    width,
}: GameCanvasProps) => {
    const {
        dogCat,
        foods,
        control,
        rows, columns,
        handleClick
    } = useGameContext();
    const gridColor0 = "#eeeeee";
    const gridColor1 = "#dddddd";
    const dogColor = "#db996e";
    const catColor0 = "#8a90a0";
    const gridSize = width / columns;
    const headExtraSize = gridSize / 1.2;
    const headExtraSizeHalf = headExtraSize / 2;
    const foodExtraSize = gridSize / 2.2;
    const foodExtraSizeHalf = foodExtraSize / 2;

    // Our assets
    const images: { [name: string]: HTMLImageElement | undefined } = {
        "dog": useImage("/dog.png", 'anonymous')[0],
        "cat": useImage("/cat.png", 'anonymous')[0],
        "sausage": useImage("/sausage.png", 'anonymous')[0],
        "fish": useImage("/fish.png", 'anonymous')[0],
    }


    // Let's draw our background chessboard grid
    let gridElements: ReactElement[] = [];
    for (let x = 0; x < columns; x++) {
        for (let y = 0; y < rows; y++) {
            let fill = gridColor0;
            if (x % 2 == 0 && y % 2 == 0) {
                fill = gridColor1;
            } else if (x % 2 != 0 && y % 2 != 0) {
                fill = gridColor1;
            }
            gridElements.push(<Rect
                key={x + "-" + y + "-" + gridElements.length}
                x={x * gridSize} y={y * gridSize}
                width={gridSize} height={gridSize}
                fill={fill}
            />);
        }
    }

    // Let's draw the DogCat character
    let dogCatElements: ReactElement[] = [];
    for (var coord of dogCat) {
        const length = dogCatElements.length;
        if (length === 0 || length === dogCat.length - 1) {
            // At the beginning and end we draw the heads
            dogCatElements.push(<Image
                key={"dogcat-" + length}
                image={(length === 0) ? images["cat"] : images["dog"]}
                x={coord.x * gridSize - headExtraSizeHalf} y={coord.y * gridSize - headExtraSizeHalf}
                width={gridSize + headExtraSize} height={gridSize + headExtraSize}
            />);
        } else { // Inbetween we draw the elemnts and lerp between the colors
            const amount = Math.min(Math.max((length + (control.current === Controller.Dog ? 4 : -4)) / (dogCat.length - 1), 0.0), 1.0);
            const fill = lerpColor(catColor0, dogColor, amount);
            const elementSize = gridSize - 2;
            dogCatElements.push(<Line
                key={coord.x + "-" + coord.y + "-" + length}
                x={coord.x * gridSize} y={coord.y * gridSize}
                fill={fill} stroke="#000" strokeWidth={gridSize / 16}
                points={[0, 0, elementSize, 0, elementSize, elementSize, 0, elementSize]}
                tension={0.2} closed
            />);
        }
    }
    // Let's re-insert cat at the back to make sure zIndex is above body
    const catElement = dogCatElements[0];
    dogCatElements.splice(0, 1);
    dogCatElements.push(catElement);

    // Now we draw all the food
    let foodElements: ReactElement[] = [];
    for (var food of foods) {
        foodElements.push(<Image
            key={"food-" + food[0].x + "-" + food[0].y}
            image={images[food[1]]}
            x={food[0].x * gridSize - foodExtraSizeHalf} y={food[0].y * gridSize - foodExtraSizeHalf}
            width={gridSize + foodExtraSize} height={gridSize + foodExtraSize}
        />);
    }

    return (
        <Stage width={width} height={height} onClick={(e: any) => handleClick(e.evt)}>
            <Layer>
                {gridElements}
            </Layer>
            <Layer>
                {dogCatElements}
            </Layer>
            <Layer>
                {foodElements}
            </Layer>
        </Stage>
    );
};

export default GameCanvas;

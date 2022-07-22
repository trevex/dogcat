import React, { ReactElement, useState, useEffect, useRef } from 'react';
import { Stage, Layer, Rect, Circle, Image } from 'react-konva';
import useImage from 'use-image';


type Coord = {
    x: number;
    y: number;
};

type GameProps = {
    width: number;
    height: number;
    gridSize: number;
};

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
// TODO: use dogcat and
//         <Line
// x={20}
// y={200}
// points={[0, 0, 100, 0, 100, 100, 0, 100]}
// tension={0.2}
// closed
// stroke="black"
// fillLinearGradientStartPoint={{ x: -50, y: -50 }}
// fillLinearGradientEndPoint={{ x: 50, y: 50 }}
// fillLinearGradientColorStops={[0, 'red', 1, 'yellow']}
// />

const Game = ({
    width,
    height,
    gridSize
}: GameProps) => {
    const gridColor0 = "#eeeeee"
    const gridColor1 = "#dddddd"
    const dogColor = "#9f6d20"
    const catColor0 = "#7fb0e3"
    const rows = height / gridSize;
    const columns = width / gridSize;
    const gridSizeHalf = gridSize / 2;
    const headExtraSize = 12;
    const headExtraSizeHalf = headExtraSize / 2;


    // Our game state
    const [dogCat, setDogCat] = useState<Coord[]>([{ x: 5, y: 5 }, { x: 6, y: 5 }, { x: 7, y: 5 }])
    const tickRate = useRef(200)
    const control = useRef<"DOG" | "CAT">("DOG")
    const direction = useRef<"L" | "R" | "U" | "D">("R")
    const digesting = useRef(10)
    const [updateCount, setUpdateCount] = useState(0)

    // Our assets
    const [dog, dogStatus] = useImage("/dog.png", 'anonymous');
    const [cat, catStatus] = useImage("/cat.png", 'anonymous');

    const updateDogCat = () => {
        // Let's use the direction and current front element facing towards
        // our next movement to compute the next element.
        const d = direction.current
        const front = (control.current === "DOG") ? dogCat[dogCat.length - 1] : dogCat[0]
        const next =
            (d === "R") && { x: front.x + 1, y: front.y } ||
            (d === "L") && { x: front.x - 1, y: front.y } ||
            (d === "U") && { x: front.x, y: front.y - 1 } ||
            { x: front.x, y: front.y + 1 }
        // Add the next element either in the front or back dependening on where
        // we are facing.
        // We only remove the element at the back if we are not digesting food.
        // If we are digesting, we are "growing".
        if (control.current === "DOG") {
            dogCat.push(next)
            if (digesting.current === 0) dogCat.shift()
        } else {
            dogCat.unshift(next)
            if (digesting.current === 0) dogCat.pop()
        }
        // We just digested an element by not removing the back element, so let's
        // substract one.
        if (digesting.current > 0) {
            digesting.current = digesting.current - 1
        }
        setDogCat(dogCat)
    }

    const handleKeyDown = (event: KeyboardEvent) => {
        event.preventDefault()
        // Changing control requires us to also figure out which direction to move back in
        if (event.code === "Space") {
            control.current = (control.current === "DOG") ? "CAT" : "DOG"
            const es = (control.current === "DOG") ? dogCat.slice(-2).reverse() : dogCat.slice(0, 2)
            const dx = es[0].x - es[1].x
            const dy = es[0].y - es[1].y
            direction.current =
                (dx > 0) && "R" ||
                (dx < 0) && "L" ||
                (dy > 0) && "D" || "U"
        }
        // Let's see if we explicitly change direction.
        // We have to make sure direction is "allowed"!
        const c = direction.current
        const d =
            (event.code === "ArrowLeft" && (c === "U" || c === "D")) && "L" ||
            (event.code === "ArrowRight" && (c === "U" || c === "D")) && "R" ||
            (event.code === "ArrowUp" && (c === "L" || c === "R")) && "U" ||
            (event.code === "ArrowDown" && (c === "L" || c === "R")) && "D" ||
            ""
        if (d !== "") {
            direction.current = d
        }
    };

    useEffect(() => {
        window.addEventListener("keydown", handleKeyDown)
        return () => {
            window.removeEventListener("keydown", handleKeyDown);
        };
    })

    // We need to loop our updates based on the dynamic `tickRate`.
    // The `updateCount` dependency achieves this dynamic looping behavior.
    useEffect(() => {
        if (updateCount >= 0) {
            const timeoutId = setTimeout(() => {
                updateDogCat()
                setUpdateCount(updateCount + 1)
            }, tickRate.current)
            return () => clearTimeout(timeoutId);
        }
        return () => { }
    }, [updateCount, direction])

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
                x={x * gridSize}
                y={y * gridSize}
                width={gridSize}
                height={gridSize}
                fill={fill}
            />);
        }
    }

    // Let's draw the DogCat character
    let dogCatElements: ReactElement[] = [];
    for (var coord of dogCat) {
        const length = dogCatElements.length
        if (length === 0) {
            dogCatElements.push(<Image
                key="cat"
                image={cat}
                x={coord.x * gridSize - headExtraSizeHalf}
                y={coord.y * gridSize - headExtraSizeHalf}
                width={gridSize + headExtraSize}
                height={gridSize + headExtraSize}
            />)
        } else if (length === dogCat.length - 1) {
            dogCatElements.push(<Image
                key="dog"
                image={dog}
                x={coord.x * gridSize - headExtraSizeHalf}
                y={coord.y * gridSize - headExtraSizeHalf}
                width={gridSize + headExtraSize}
                height={gridSize + headExtraSize}
            />)
        } else {
            const fill = lerpColor(catColor0, dogColor, length / (dogCat.length - 1))
            dogCatElements.push(<Circle
                key={coord.x + "-" + coord.y + "-" + length}
                x={coord.x * gridSize + gridSizeHalf}
                y={coord.y * gridSize + gridSizeHalf}
                fill={fill}
                stroke="#000"
                strokeWidth={1.5}
                radius={gridSize / 2}
            />)
        }
    }
    // Let's re-insert cat at the back to make sure zIndex is above body
    const catElement = dogCatElements[0]
    dogCatElements.splice(0, 1)
    dogCatElements.push(catElement)

    return (
        <Stage width={width} height={height}>
            <Layer>
                {gridElements}
            </Layer>
            <Layer>
                {dogCatElements}
            </Layer>
        </Stage>
    )
};

export default Game;
